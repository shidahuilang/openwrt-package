'use strict';
'require view';
'require form';
'require ui';
'require uci';
'require rpc';
'require fs';

var callInitAction = rpc.declare({
    object: 'luci',
    method: 'setInitAction',
    params: ['name', 'action'],
    expect: { result: false }
});

return view.extend({
    handleSaveApply: function(ev) {
        return this.handleSave(ev)
            .then(() => ui.changes.apply())
            .then(() => uci.load('qosmate'))
            .then(() => uci.get_first('qosmate', 'global', 'enabled'))
            .then(enabled => {
                if (enabled === '0') {
                    return fs.exec_direct('/etc/init.d/qosmate', ['stop']);
                } else {
                    return fs.exec_direct('/etc/init.d/qosmate', ['restart']);
                }
            })
            .then(() => {
                ui.hideModal();
                window.location.reload();
            })
            .catch(err => {
                ui.hideModal();
                ui.addNotification(null, E('p', _('Failed to save settings or update QoSmate service: ') + err.message));
            });
    },
    
    render: function() {
        var m, s, o;

        m = new form.Map('qosmate', _('QoSmate Advanced Settings'), _('Configure advanced settings for QoSmate.'));

        s = m.section(form.NamedSection, 'advanced', 'advanced', _('Advanced Settings'));
        s.anonymous = true;

        function createOption(name, title, description, placeholder, datatype) {
            var opt = s.option(form.Value, name, title, description);
            opt.datatype = datatype || 'string';
            opt.rmempty = true;
            opt.placeholder = placeholder;
            
            if (datatype === 'uinteger') {
                opt.validate = function(section_id, value) {
                    if (value === '' || value === null) return true;
                    if (!/^\d+$/.test(value)) return _('Must be a non-negative integer or empty');
                    return true;
                };
            }
            if (datatype === 'integer') {
                opt.validate = function(section_id, value) {
                    if (value === '' || value === null) return true;
                    if (!/^-?\d+$/.test(value)) return _('Must be an integer or empty');
                    return true;
                };
            }
            return opt;
        }

        o = s.option(form.Flag, 'PRESERVE_CONFIG_FILES', _('Preserve Config Files'), _('Preserve configuration files during system upgrade'));
        o.rmempty = false;

        o = s.option(form.Flag, 'WASHDSCPUP', _('Wash DSCP Egress'), _('Sets DSCP to CS0 for outgoing packets after classification'));
        o.rmempty = false;

        o = s.option(form.Flag, 'WASHDSCPDOWN', _('Wash DSCP Ingress'), _('Sets DSCP to CS0 for incoming packets before classification'));
        o.rmempty = false;

        createOption('BWMAXRATIO', _('Bandwidth Max Ratio'), _('Max download/upload ratio to prevent upstream congestion'), _('Default: 20'), 'uinteger');
        createOption('ACKRATE', _('ACK Rate'), _('Sets rate limit for TCP ACKs, helps prevent ACK flooding / set to 0 to disable ACK rate limit'), _('Default: 5% of UPRATE'), 'uinteger');

        o = s.option(form.Flag, 'UDP_RATE_LIMIT_ENABLED', _('Enable UDP Rate Limit'), _('Downgrades UDP traffic exceeding 450 pps to lower priority'));
        o.rmempty = false;

        o = s.option(form.Flag, 'TCP_UPGRADE_ENABLED', _('Boost Low-Volume TCP Traffic'), _('Upgrade DSCP to AF42 for TCP connections with less than 150 packets per second. This can improve responsiveness for interactive TCP services like SSH, web browsing, and instant messaging.'));
        o.rmempty = false;
        o.default = '1';

        createOption('UDPBULKPORT', _('UDP Bulk Ports'), _('Specify UDP ports for bulk traffic'), _('Default: none'));
        createOption('TCPBULKPORT', _('TCP Bulk Ports'), _('Specify TCP ports for bulk traffic'), _('Default: none'));

        createOption('MSS', _('TCP MSS'), _('Maximum Segment Size for TCP connections. This setting is only active when the upload or download bandwidth is less than 3000 kbit/s. Leave empty to use the default value.'), _('Default: 536'), 'uinteger');

        o = s.option(form.ListValue, 'NFT_HOOK', _('Nftables Hook'), _('Select the nftables hook point for the dscptag chain'));
        o.value('forward', _('forward'));
        o.value('postrouting', _('postrouting'));
        o.default = 'forward';
        o.rmempty = false;

        createOption('NFT_PRIORITY', _('Nftables Priority'), _('Set the priority for the nftables chain. Lower values are processed earlier. Default is 0 | mangle is -150.'), _('0'), 'integer');

        return m.render();
    }
});
