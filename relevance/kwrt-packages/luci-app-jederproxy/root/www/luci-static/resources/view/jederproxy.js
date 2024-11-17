'use strict';
'require view';
'require uci';
'require rpc';
'require form';
'require fs';
'require ui';
'require network';
'require tools.widgets as widgets';

var callInitList, callInitAction, ServiceController;

const FEATURE_FLAGS = {
    have_fw3: false,  // %FLAG_NO_FW3% managed by build system
    have_fw4: false,  // %FLAG_NO_FW4% managed by build system
    // %FLAG_FW3% have_fw3: true,  // uncomment by build system on fw3
    // %FLAG_FW4% have_fw4: true,  // uncomment by build system on fw4
};

callInitList = rpc.declare({
    object: 'luci',
    method: 'getInitList',
    params: [ 'name' ],
    expect: { '': {} }
}),

callInitAction = rpc.declare({
    object: 'luci',
    method: 'setInitAction',
    params: [ 'name', 'action' ],
    expect: { result: false }
});


function check_resource_files(load_result) {
    let geoip_existence = false;
    let geoip_size = 0;
    let geosite_existence = false;
    let geosite_size = 0;
    let firewall4 = false;
    let xray_bin_default = false;
    let optional_features = {};
    for (const f of load_result) {
        if (f.name == "xray") {
            xray_bin_default = true;
        }
        if (f.name == "geoip.dat") {
            geoip_existence = true;
            geoip_size = '%.2mB'.format(f.size);
        }
        if (f.name == "geosite.dat") {
            geosite_existence = true;
            geosite_size = '%.2mB'.format(f.size);
        }
        if (f.name == "firewall_include.ut") {
            firewall4 = true;
        }
        if (f.name.startsWith("optional_feature_")) {
            optional_features[f.name] = true;
        }
    }
    return {
        geoip_existence: geoip_existence,
        geoip_size: geoip_size,
        geosite_existence: geosite_existence,
        geosite_size: geosite_size,
        optional_features: optional_features,
        firewall4: firewall4,
        xray_bin_default: xray_bin_default,
    }
}

function check_dns_format(_, dns) {
    if (/^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/.test(dns)) {
        // IPv4 Address
        return true;
    }
    if (/(https|tcp|quic)(\+local)?:\/\/([-\w\d@:%._\+~#=]{1,256}\.[\w\d()]{1,6}\b)(:(\d+))?([-\w\d()@:%_\+.~#?&\/=]*)/.test(dns)) {
        // DoH/TCP/QUIC Server Address
        return true;
    }

    if (dns === "localhost") {
        return true;
    }
    return "Invalid DNS address";
}

ServiceController = form.DummyValue.extend({
    handleAction: function(name, action, ev) {
        return callInitAction(name, action).then(function(success) {
            ui.addNotification(null, E('p', _('Service %s success.').format(action)), 'info');
        }).catch(function (e) {
            ui.addNotification(null, E("p", _('Unable to perform service %s: %s').format(action, e.message)), "error");
        });
    },

    renderWidget: function(section_id, option_id, cfgvalue) {
        return E([], [
            E('span', { 'class': 'control-group' }, [
                E('button', {
                    class: 'btn cbi-button-%s'.format(this.service_enabled ? 'positive' : 'negative'),
                    click: ui.createHandlerFn(this, function() {
                        return callInitAction(this.service_name, this.service_enabled ? "disable": "enable").then(rc => ui.addNotification(null, E('p', _('Toggle startup success.')), 'info'));
                    }),
                    disabled: this.control_disabled
                }, this.service_enabled ? _('Enabled') : _('Disabled')),
                E('button', { 'class': 'btn cbi-button-action', 'click': ui.createHandlerFn(this, 'handleAction', this.service_name, 'start'), 'disabled': this.control_disabled }, _('Start')),
                E('button', { 'class': 'btn cbi-button-action', 'click': ui.createHandlerFn(this, 'handleAction', this.service_name, 'restart'), 'disabled': this.control_disabled }, _('Restart')),
                E('button', { 'class': 'btn cbi-button-action', 'click': ui.createHandlerFn(this, 'handleAction', this.service_name, 'stop'), 'disabled': this.control_disabled }, _('Stop'))
            ])
        ]);
    },
});

return view.extend({
    handleServiceReload: function (ev) {
        return callInitAction("jederproxy", "restart").then(function(rc) {
            ui.addNotification(null, E('p', _('Reload service success.')), 'info');
        }).catch(function (e) {
            ui.addNotification(null, E("p", _('Unable to reload service: %s').format(e.message)), "error");
        });
    },

    handleSaveApply: function (ev, mode) {
        return this.__base__.handleSaveApply(ev, mode).then(this.handleServiceReload);
    },

    load: function () {
        return Promise.all([
            uci.load("jederproxy"),     // config_data
            fs.list("/usr/share/jederproxy"),   // xray_dir
            network.getHostHints(),     // network_hosts
            L.resolveDefault(fs.read("/var/run/jederproxy.pid"), null),     // xray_pid
            callInitList("jederproxy"),     // xray_service_status
        ])
    },

    render: function (load_result) {
        const config_data = load_result[0];
        const xray_dir = load_result[1];
        const network_hosts = load_result[2];
        const xray_pid = load_result[3];
        const xray_service_status = load_result[4]["jederproxy"];
        const geoip_direct_code = uci.get_first(config_data, "general", "geoip_direct_code");
        const { geoip_existence, geoip_size, geosite_existence, geosite_size, optional_features, firewall4, xray_bin_default } = check_resource_files(xray_dir);
        const status_text = xray_pid ? (_("[Xray is running]") + `[PID:${xray_pid.trim()}]`) : _("[Xray is stopped]");

        let asset_file_status = _('WARNING: at least one of asset files (geoip.dat, geosite.dat) is not found under /usr/share/jederproxy. Xray may not work properly. See <a href="https://github.com/ttimasdf/luci-app-jederproxy">here</a> for help.')
        if (geoip_existence) {
            if (geosite_existence) {
                asset_file_status = _('Asset files check: ') + `geoip.dat ${geoip_size}; geosite.dat ${geosite_size}. ` + _('Report issues or request for features <a href="https://github.com/ttimasdf/luci-app-jederproxy">here</a>.')
            }
        }

        const m = new form.Map('jederproxy', _('Xray'), status_text + " " + asset_file_status);

        var s, o, ss;

        s = m.section(form.TypedSection, 'general');
        s.addremove = false;
        s.anonymous = true;

        s.tab('general', _('General Settings'));

        o = s.taboption('general', form.ListValue, 'server', _('Server Instance'))
        o.datatype = "uciname"
        // o.value("disabled", _("Disabled"))
        for (const v of uci.sections(config_data, "server")) {
            o.value(v[".name"], v.alias || v[".name"])
        }

        o = s.taboption('general', ServiceController, "_service", _("Service Control"), _("Refresh the page manually for actions to take effect"));
        o.service_name = "jederproxy"
        o.service_enabled = xray_service_status.enabled;
        o.service_index = xray_service_status.index;

        o = s.taboption('general', form.Flag, 'dnsmasq_takeover_enable', _('Enable dnsmasq Takeover'), _('Enable this option force using xray dns inbound port as dnsmasq\'s upstream server.'))

        o = s.taboption('general', form.Flag, 'transparent_proxy_enable', _('Enable Transparent Proxy'), _('This enables DNS query forwarding and TProxy for both TCP and optionally UDP connections.'))

        o = s.taboption('general', form.Flag, 'tproxy_enable_udp', _('Enable UDP Forward'), _('UDP Forward could be switched off for better compatibility with some service providers'))
        o.depends("transparent_proxy_enable", "1")

        o = s.taboption('general', form.SectionValue, "jederproxy_servers", form.GridSection, 'server', _('Proxy Servers'), _("Servers are referenced by index (order in the following list). Deleting servers may result in changes of upstream servers actually used by proxy and bridge."))
        ss = o.subsection
        ss.sortable = false
        ss.anonymous = true
        ss.addremove = true

        ss.tab('general', _('General Settings'));

        o = ss.taboption('general', form.Value, "alias", _("Alias"))
        o.rmempty = true

        o = ss.taboption('general', form.Value, 'executable_path', _('Proxy Executable Path'))
        o.rmempty = false

        o = ss.taboption('general', form.ListValue, 'server_type', _('Server Type'))
        o.value("mihomo")
        o.value("xray")
        o.default = "mihomo"

        o = ss.taboption('general', form.ListValue, 'config_type', _('Config file type'))
        o.value("directory")
        o.value("file")
        o.default = "file"

        o = ss.taboption('general', form.Value, 'config_directory', _('Config directory path'))
        o.depends("config_type", "directory")
        o.rmempty = false

        o = ss.taboption('general', form.Value, 'config_file', _('Config file path'))
        o.depends("config_type", "file")
        o.rmempty = false

        s.tab('proxy', _('iptables/nftables Settings'));

        o = s.taboption('proxy', form.Value, 'tproxy_port', _('Transparent Proxy Port'), _('The <code>tproxy-port</code> value in mihomo/clash or <code>port</code> value of dokodemo inbound in v2ray/xray'))
        o.datatype = 'port'
        o.default = 7892

        o = s.taboption('proxy', form.Value, 'packet_mark_id', _('Packet Mark Number'), _('The <code>routing-mark</code> value in mihomo/clash or <code>streamSettings.sockopt.mark</code> value in v2ray/xray'))
        o.datatype = 'range(1, 255)'
        o.default = 255

        // if (firewall4) {
        //     o = s.taboption('proxy', form.DynamicList, 'uids_direct', _('Skip Proxy for uids'), _("Processes started by users with these uids won't be forwarded through Xray."))
        //     o.datatype = "integer"

        //     o = s.taboption('proxy', form.DynamicList, 'gids_direct', _('Skip Proxy for gids'), _("Processes started by users in groups with these gids won't be forwarded through Xray."))
        //     o.datatype = "integer"
        // }

        o = s.taboption('proxy', form.DynamicList, 'whitelist_process_uids', _('Whitelist UIDs'), _('Ignore local traffic of specific UIDs'))
        o.rmempty = true

        o = s.taboption('proxy', form.DynamicList, 'whitelist_process_gids', _('Whitelist GIDs'), _('Ignore local traffic of specific GIDs'))
        o.rmempty = true


        o = s.taboption('proxy', widgets.DeviceSelect, 'lan_interface', _("LAN Interface"))
        o.noaliases = true
        o.rmempty = false
        o.nocreate = true

        o = s.taboption('proxy', form.SectionValue, "access_control_lan_hosts", form.TableSection, 'lan_hosts', _('LAN Hosts Access Control'), _("Will not enable transparent proxy for these MAC addresses."))

        ss = o.subsection;
        ss.sortable = false
        ss.anonymous = true
        ss.addremove = true

        o = ss.option(form.Value, "macaddr", _("MAC Address"))
        L.sortedKeys(network_hosts.hosts).forEach(function (mac) {
            o.value(mac, E([], [mac, ' (', E('strong', [network_hosts.hosts[mac].name || L.toArray(network_hosts.hosts[mac].ipaddrs || network_hosts.hosts[mac].ipv4)[0] || L.toArray(network_hosts.hosts[mac].ip6addrs || network_hosts.hosts[mac].ipv6)[0] || '?']), ')']));
        });

        o.datatype = "macaddr"
        o.rmempty = false

        o = ss.option(form.ListValue, "bypassed", _("Access Control Strategy"))
        o.value("0", "Always forwarded")
        o.value("1", "Always bypassed")
        o.rmempty = false

        s.tab('dns', _('DNS Settings'));

        o = s.taboption('dns', form.Value, 'dns_port', _('Xray DNS Server Port'), _("Do not use port 53 (dnsmasq), port 5353 (mDNS) or other common ports"))
        o.datatype = 'port'
        o.default = 5300

        o = s.taboption('dns', form.Value, 'dns_count', _('Extra DNS Server Ports'), _('Listen for DNS Requests on multiple ports (all of which serves as dnsmasq upstream servers).<br/>For example if Xray DNS Server Port is 5300 and use 3 extra ports, 5300 - 5303 will be used for DNS requests.<br/>Increasing this value may help reduce the possibility of temporary DNS lookup failures.'))
        o.datatype = 'range(0, 50)'
        o.default = 0

        s.tab('transparent_proxy_rules', _('Transparent Proxy Rules'));

        o = s.taboption('transparent_proxy_rules', form.DynamicList, "wan_bypass_rules", _("Bypassed IP"), _("Requests to these IPs won't be forwarded through your proxy."))
        o.datatype = "ip4addr"
        o.rmempty = true

        o = s.taboption('transparent_proxy_rules', form.Value, 'wan_bypass_rule_file', _('Bypassed IP list file'))
        o.rmempty = false

        o = s.taboption('transparent_proxy_rules', form.DynamicList, "wan_forward_rules", _("Forwarded IP"))
        o.datatype = "ip4addr"
        o.rmempty = true

        o = s.taboption('transparent_proxy_rules', form.Value, 'wan_forward_rule_file', _('Forwarded IP list file'))
        o.rmempty = false


        s.tab('procd_options', _('Process Options'))

        function rlimit_validate(section_id, value) {
            let rlimit_regex = new RegExp("^[0-9]+ [0-9]+$","g");
            if (value == "" || rlimit_regex.test(value)) {
                return true
            } else {
                return "rlimit format: [soft] [hard]"
            }
        }
        o = s.taboption('procd_options', form.Value, 'rlimit_nofile', _('Max Open Files'), _('Set xray process resource limit <code>RLIMIT_NOFILE</code>: max number of open file descriptors.'))
        o.value("", "[unset]")
        o.value("1024 4096", "1024 4096 (system default)")
        o.value("8192 16384")
        o.value("102400 204800")
        o.default = ""
        o.validate = rlimit_validate

        o = s.taboption('procd_options', form.Value, 'rlimit_data', _('Max Allocated Memory'), _('Set xray process resource limit <code>RLIMIT_DATA</code>: max memory usage.'))
        o.value("", "[unset]")
        o.value("52428800 52428800", "50 MiB")
        o.value("104857600 104857600", "100 MiB")
        o.value("209715200 209715200", "200 MiB")
        o.value("419430400 419430400", "400 MiB")
        o.default = ""
        o.validate = rlimit_validate

        return m.render();
    }
});
