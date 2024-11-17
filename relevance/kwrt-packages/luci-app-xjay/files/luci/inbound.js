'use strict';
'require view';
'require form';
'require uci';
'require xjay';

return view.extend({

    load: function () {
        return Promise.all([
            uci.load("xjay")
        ])
    },

    render:function(load_result){
        const config_data = load_result[0];

        var m, s, o, ss;
        m = new form.Map('xjay', _('Inbounds'), _('Inbound Settings for Xjay.'));

        s = m.section(form.TypedSection, 'inbound');
        s.addremove = false;
        s.anonymous = true;

        // as blow are some general config options for inbound services
        s.tab('inbound', _('Inbound'));

        o = s.taboption("inbound", form.ListValue, "default_inbound", _("Default Tproxy Inbound"),  _("This is needed for firewall rules, if it's not set then the proxy will not work! Currently only support dokodemo-door with tproxy."));
        o.validate = function(sid, s){
            var protocol, sockopt_tproxy;

            for (var v of uci.sections(config_data, "inbound_service")) {
                if (v.tag == s){
                    protocol = v.protocol;
                    sockopt_tproxy = v.sockopt_tproxy;
                }
            }

            // the protocol must be dokodemo-door and tproxy because firewall rules need these
            if (protocol == 'dokodemo-door' && sockopt_tproxy == 'tproxy') {
                return true;
            }
            else {
                return _('Must be: %s').format(_('dekodemo-door and tproxy'));
            }
        };
        for (var v of uci.sections(config_data, "inbound_service")) {
            o.value(v.tag);
        }

        // starts from here is the inbound services table with the ability to add/remove/edit service

        o = s.taboption("inbound", form.SectionValue, "xray_inbounds", form.GridSection, 'inbound_service', _('Xray Inbounds'), _("Inbound configurations are needed for traffic forwarding into proxy."));
        ss = o.subsection;
        ss.sortable = true;
        ss.anonymous = true;
        ss.addremove = true;
        ss.nodescriptions = true;

        // general tab of the service configuration popup

        ss.tab('general', _('General Settings'));

        o = ss.taboption('general', form.Value, "tag", _("Tag for the Inbound"), _('It shall be unique. This will be also used for routing rules.'));
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;

        o = ss.taboption('general', form.Value, 'listen', _('Listening Address'), _('Optional. Could be IP address or unix domain socket'));
        o.validate = xjay.validateIPUnixSocket;
        o.placeholder = '127.0.0.1';
        o.modalonly = true;

        o = ss.taboption('general', form.Value, 'port', _('Listening Port'), _('It shall be unique. This will be the primary identifier for firewall rules to forward inbound traffic.'));
        o.datatype = 'port';
        o.rmempty = false;
        o.placeholder = '12344';

        // protocol tab of the service configuration popup

        ss.tab('protocol', _('Protocol Settings'));

        o = ss.taboption('protocol', form.DummyValue, '_selectconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Porotol and Security Selection</strong>');
        };

        o = ss.taboption('protocol', form.ListValue, "protocol", _("Protocol"), _('The protocol to communicate with a client or another program. Choose the one suites best for your usage. See <a href="https://xtls.github.io/config/inbounds/#%E5%8D%8F%E8%AE%AE%E5%88%97%E8%A1%A8">here</a> for help.'));
        o.value("dokodemo-door", "Dokodemo-Door");
        o.value("http", "HTTP");
        o.value("shadowsocks", "Shadowsocks");
        o.value("socks", "Socks");
        o.value("trojan", "Trojan");
        o.value("vless", "VLESS");
        o.value("vmess", "VMess");
        o.rmempty = false;

        o = ss.taboption('protocol', form.ListValue, 'stream_security', _('Stream Security'));
        o.value("none", "None");
        o.value("tls", "TLS");
        o.value("xtls", "XTLS (deprecated)");
        o.value("reality", "REALITY");
        o.rmempty = false;

        // protocol tab - configurations for each protocol

        o = ss.taboption('protocol', form.DummyValue, '_protoconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Configuration Options for Protocol</strong>');
        };

        // protocol tab - dokodemo-door config options

        o = ss.taboption('protocol', form.Flag, 'dokodemo_followredirect', _('Flow Redirect'), _('This is normally used for transparent proxy. If you set tproxy firewall rules, this shall be enabled.'));
        o.depends("protocol", "dokodemo-door");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'dokodemo_address', _('Forwarding Address'), _('Traffic will be forwarded to this address. Could be IP address or domain name. See <a href="https://xtls.github.io/config/inbounds/dokodemo.html#inboundconfigurationobject">here</a> for help.'));
        o.depends("dokodemo_followredirect", "false");
        o.datatype = 'or(ip4addr, ip6addr, hostname)';
        o.placeholder = '8.8.8.8';
        o.modalonly = true;
        o.optional = true;

        o = ss.taboption('protocol', form.Value, 'dokodemo_port', _('Forwarding Port'), _('Traffic will be forwarded to this port of assigned address.'));
        o.depends("dokodemo_followredirect", "false");
        o.datatype = 'port';
        o.placeholder = '53';
        o.modalonly = true;
        o.optional = true;

        o = ss.taboption('protocol', form.MultiValue, "network", _("Network Type"), _("Network type to be proxyed."));
        o.depends("protocol", "dokodemo-door");
        o.value("tcp", "TCP");
        o.value("udp", "UDP");
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'dokodemo_timeout', _('Connection Timeout'), _('If no data has been trasmitted during the timeout, then the connection will be disconnected.'));
        o.depends("protocol", "dokodemo-door");
        o.datatype = 'uinteger';
        o.placeholder = '0';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'dokodemo_level', _('Policy Level'), _('User level for configured policies. This is useful for serving many users, normally it is not needed. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.depends("protocol", "dokodemo-door");
        o.datatype = 'uinteger';
        o.placeholder = '0';
        o.modalonly = true;

        // protocol tab - http config options

        o = ss.taboption('protocol', form.ListValue, "http_auth", _("Authentication"), _('If this inbound port is exposed to internet, you may need enable authentication for security purpose. Each protocol may has different authentication configurations. See <a href="https://xtls.github.io/config/inbounds/socks.html#accountobject">here</a> for help.'));
        o.depends("protocol", "http");
        o.value("noauth", "No authentication");
        o.value("password", "Authenticate with password");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.MultiValue, 'http_user', _('Select Users'), _('User name and password will be configured with selected users.'));
        o.depends("http_auth", "password");
        o.rmempty = false;
        o.modalonly = true;
        for (var v of uci.sections(config_data, "user")) {
            o.value(v.name);
        }

        o = ss.taboption('protocol', form.Flag, "http_allocatransparent", _("Forward all http traffic"), _("Forward http requests to destination instead of proxy the requests."));
        o.depends("protocol", "http");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'http_level', _('Policy Level'), _('User level for configured policies. This is useful for serving many users, normally it is not needed. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.depends("protocol", "http");
        o.datatype = 'uinteger';
        o.placeholder = '0';
        o.modalonly = true;

        // protocol tab - socks config options

        o = ss.taboption('protocol', form.ListValue, "socks_auth", _("Authentication"), _('If this inbound port is exposed to internet, you may need enable authentication for security purpose. Each protocol may has different authentication configurations. See <a href="https://xtls.github.io/config/inbounds/socks.html#accountobject">here</a> for help.'));
        o.depends("protocol", "socks");
        o.value("noauth", "No authentication");
        o.value("password", "Authenticate with password");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.MultiValue, 'socks_user', _('Select Users'), _('User name and password will be configured with selected users.'));
        o.depends("socks_auth", "password");
        o.rmempty = false;
        o.modalonly = true;
        for (var v of uci.sections(config_data, "user")) {
            o.value(v.name);
        }

        o = ss.taboption('protocol', form.Flag, "socks_udp", _("Enable UDP Proxy"));
        o.depends("protocol", "socks");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'socks_ip', _('Device Local IP Address'), _('If UDP is enabled, xray needs to know device local IP address. See <a href="https://xtls.github.io/config/inbounds/socks.html#inboundconfigurationobject">here</a> for help.'));
        o.depends("socks_udp", "true");
        o.datatype = 'or(ip4addr, ip6addr)';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'socks_level', _('Policy Level'), _('User level for configured policies. This is useful for serving many users, normally it is not needed. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.depends("protocol", "socks");
        o.datatype = 'uinteger';
        o.placeholder = '0';
        o.modalonly = true;

        // protocol tab - shadowsocks config options

        o = ss.taboption('protocol', form.MultiValue, 'ss_user', _('Select Users'), _('Password, email and user level will be configured with selected users.'));
        o.depends("protocol", "shadowsocks");
        o.rmempty = false;
        o.modalonly = true;
        for (var v of uci.sections(config_data, "user")) {
            o.value(v.name);
        }

        o = ss.taboption('protocol', form.ListValue, "ss_method", _("Shadowsocks Encrypt Method"));
        o.depends("protocol", "shadowsocks");
        o.value("none", "none");
        o.value("aes-256-gcm", "aes-256-gcm");
        o.value("aes-128-gcm", "aes-128-gcm");
        o.value("chacha20-poly1305", "chacha20-poly1305");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.option(form.MultiValue, "ss_network", _("Network Type"));
        o.depends("protocol", "shadowsocks");
        o.value("tcp", "TCP");
        o.value("udp", "UDP");
        o.modalonly = true;

        // protocol tab - trojan config options

        o = ss.taboption('protocol', form.MultiValue, 'trojan_user', _('Select Users'), _('Password, email and user level will be configured with selected users.'));
        o.depends("protocol", "trojan");
        o.rmempty = false;
        o.modalonly = true;
        for (var v of uci.sections(config_data, "user")) {
            o.value(v.name);
        }

        // protocol tab - vless config options

        o = ss.taboption('protocol', form.MultiValue, 'vless_user', _('Select Users'), _('Vless ID, email and user level will be configured with selected users.'));
        o.depends("protocol", "vless");
        o.rmempty = false;
        o.modalonly = true;
        for (var v of uci.sections(config_data, "user")) {
            o.value(v.name);
        }

        o = ss.taboption('protocol', form.ListValue, "vless_flow", _('Vless Flow'));
        o.depends({"protocol": "vless", "stream_security": "tls"});
        o.depends({"protocol": "vless", "stream_security": "xtls"});
        o.depends({"protocol": "vless", "stream_security": "reality"});
        o.value("none", "none");
        o.value("xtls-rprx-vision", "xtls-rprx-vision");
        o.value("xtls-rprx-vision-udp443", "xtls-rprx-vision-udp443")
        o.value("xtls-rprx-origin", "xtls-rprx-origin");
        o.value("xtls-rprx-origin-udp443", "xtls-rprx-origin-udp443");
        o.value("xtls-rprx-direct", "xtls-rprx-direct");
        o.value("xtls-rprx-direct-udp443", "xtls-rprx-direct-udp443");
        o.value("xtls-rprx-splice", "xtls-rprx-splice");
        o.value("xtls-rprx-splice-udp443", "xtls-rprx-splice-udp443");
        o.rmempty = false;
        o.modalonly = true;

        // protocol tab - vmess config options

        o = ss.taboption('protocol', form.MultiValue, 'vmess_user', _('Select Users'), _('Vmess ID, email and user level will be configured with selected users.'));
        o.depends("protocol", "vmess");
        o.rmempty = false;
        o.modalonly = true;
        for (var v of uci.sections(config_data, "user")) {
            o.value(v.name);
        }

        o = ss.taboption('protocol', form.ListValue, "vmess_alterid", _("Vmess AlterId"));
        o.depends("protocol", "vmess");
        o.value(0, "0 (this enables VMessAEAD)");
        o.value(1, "1");
        o.value(4, "4");
        o.value(16, "16");
        o.value(64, "64");
        o.value(256, "256");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'vmess_detour', _('Vmess Detour'), _('This inbound must be vmess protocol!'));
        o.depends("protocol", "vmess");
        o.validate = xjay.validateStingWhitespace;
        o.placeholder = 'another_inbound_tag';
        o.modalonly = true;

        // protocol tab - tls or xtls settings

        o = ss.taboption('protocol', form.DummyValue, '_tlsconfig');
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Configuration Options for TLS</strong>');
        };

        o = ss.taboption('protocol', form.Flag, 'tls_rejectnuknownsni', _('Reject Unkown SNI'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.MultiValue, 'tls_alpn', _('TLS ALPN'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.value("h2", "h2");
        o.value("http/1.1", "http/1.1");
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "tls_minversion", _("Minimum TLS Version"));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.validate = xjay.validateStingWhitespace;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "tls_maxversion", _("Maximum TLS Version"));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.validate = xjay.validateStingWhitespace;
        o.modalonly = true;

        o = ss.taboption('protocol', form.DynamicList, 'tls_ciphersuites', _('Supported Cipher Suites'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'cert_ocspStapling', _('Cert Reload Duration'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.datatype = 'uinteger';
        o.placeholder = '3600';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Flag, 'cert_onetimeloading', _('Cert One Time Loading'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.ListValue, 'cert_usage', _('Cert Usage'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.value("encipherment", "Verification and Encryption");
        o.value("verify", "Verification");
        o.value("issue", "Sign Other Certs");
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "cert_certificatefile", _("Cert File Path"));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.validate = xjay.validateDirectory;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "cert_certificatekeyfile", _("Cert Key File Path"));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.validate = xjay.validateDirectory;
        o.rmempty = false;
        o.modalonly = true;

        // protocol tab - reality settings

        o = ss.taboption('protocol', form.DummyValue, '_realityconfig');
        o.depends('stream_security', "reality");
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Configuration Options for REALITY</strong>');
        };

        o = ss.taboption('protocol', form.Flag, 'reality_show', _('Show Debug Info'));
        o.depends('stream_security', "reality");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_dest', _('Destination Address'));
        o.depends('stream_security', "reality");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_xver', _('Proxy Version'));
        o.depends('stream_security', "reality");
        o.datatype= 'uinteger';
        o.modalonly = true;

        o = ss.taboption('protocol', form.DynamicList, "reality_servername", _("Server Name List"), _('Available server name list for clients.'));
        o.depends('stream_security', "reality");
        o.datatype = 'hostname';
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_privatekey', _('Private Key'));
        o.depends('stream_security', "reality");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_minclientver', _('Minimum Client Version'));
        o.depends('stream_security', "reality");
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_maxclientver', _('Maximum Client Version'));
        o.depends('stream_security', "reality");
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_maxtimediff', _('Maximum Time Difference'), _('Allowed maxmium time different between client and server in mini sections.'));
        o.depends('stream_security', "reality");
        o.datatype= 'uinteger';
        o.modalonly = true;

        o = ss.taboption('protocol', form.DynamicList, "reality_shortid", _("Short ID List"), _('Available short ID list for clients.'));
        o.depends('stream_security', "reality");
        o.validate = xjay.validateShortID;
        o.rmempty = false;
        o.modalonly = true;

        // protocol tab - sniffing settings

        o = ss.taboption('protocol', form.DummyValue, '_sniffingconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Sniffing Settings for Inbound</strong>');
        };

        o = ss.taboption('protocol', form.Flag, 'sniffing_enabled', _('Enable Sniffing'), _('Sniff the traffic type and overwrite its destination. This is useful when you using built-in dns server to domain based routing rules. See <a href="https://xtls.github.io/config/inbound.html#sniffingobject">here</a> for help.'));
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.MultiValue, "sniffing_destoverride", _("Destination Override"), _('If the traffic matches selected type, override the destination according to the destination in the packet. Choose the one suites best for your usage. See <a href="https://xtls.github.io/config/inbound.html#sniffingobject">here</a> for help.'));
        o.depends({ "sniffing_enabled": "true" });
        o.value("http", "HTTP");
        o.value("tls", "TLS");
        o.value("quic", "QUIC");
        o.value("fakedns", "FakeDNS");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Flag, 'sniffing_metadataonly', _('Metadata Only'), _('Use the metadata of the connection to sniff protocol. See <a href="https://xtls.github.io/config/inbound.html#sniffingobject">here</a> for help.'));
        o.depends({ "sniffing_enabled": "true" });
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.DynamicList, "sniffing_domainsexcluded", _("Excluded Domains"), _('If the traffic matches selected type but destination in this list, then the destination will not be override. Choose the one suites best for your usage. See <a href="https://xtls.github.io/config/inbound.html#sniffingobject">here</a> for help.'));
        o.depends({ "sniffing_enabled": "true" });
        o.datatype = 'hostname';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Flag, 'sniffing_routeonly', _('Route Only'), _('Use sniffed domain for routing only but still access through IP. Reduces unnecessary DNS requests. See <a href="https://xtls.github.io/config/inbound.html#sniffingobject">here</a> for help.'));
        o.depends({ "sniffing_enabled": "true" });
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        // protocol tab - fallback selection

        o = ss.taboption('protocol', form.DummyValue, '_fallbackselection');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Select fallbacks for Inbound</strong>');
        };

        o = ss.taboption('protocol', form.MultiValue, 'fallback', _('Fallbacks'), _('Select fallbacks fro this inbound service.'));
        for (var v of uci.sections(config_data, "fallback")) {
            o.value(v.tag);
        }

        // transport tab of the server configuration popup

        ss.tab('transport', _('Transport Settings'));

        // transport tab - sockopt settings

        o = ss.taboption('transport', form.DummyValue, '_sockoptconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Configuration Options for Sockopt</strong>');
        };

        o = ss.taboption('transport', form.Flag, 'sockopt_tcpfastopen', _('TCP Fast Open'));
        o.enabled = 'true';
        o.disabled = 'false';
        o.optional = true;
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, 'sockopt_tproxy', _('Transparent Proxy'));
        o.value("redirect", "Redirect Mode");
        o.value("tproxy", "Tproxy Mode");
        o.value("off", "OFF");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.Flag, 'sockopt_acceptproxyprotocol', _('Accept Proxy Protocol'));
        o.enabled = 'true';
        o.disabled = 'false';
        o.optional = true;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, 'sockopt_tcpkeepaliveinterval', _('TCP Keep Alive Interval'));
        o.datatype = 'uinteger';
        o.placeholder = '25';
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, 'sockopt_tcpcongestion', _('TCP Congestion Algorithm'));
        o.value("bbr", "BBR (Recommended)");
        o.value("cubic", "CUBIC");
        o.value("reno", "RENO");
        o.optional = true;
        o.modalonly = true;

        // transport tab - network types

        o = ss.taboption('transport', form.DummyValue, '_networktypeoptconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Configuration Options for Network</strong>');
        };

        o = ss.taboption('transport', form.ListValue, 'stream_network', _('Network Type'));
        o.value("tcp", "TCP");
        o.value("kcp", "mKCP");
        o.value("ws", "WebSocket");
        o.value("h2", "HTTP/2");
        o.value("quic", "QUIC");
        o.value("ds", "Domain Socket");
        o.value("grpc", "gRPC");
        o.rmempty = false;

        // transport tab - tcp settings

        o = ss.taboption('transport', form.Flag, "tcp_acceptproxyprotocol", _("Pass orginal IP and port"));
        o.depends("stream_network", "tcp");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, "tcp_type", _("TCP Fake Header Type"));
        o.depends("stream_network", "tcp");
        o.value("none", _("None"));
        o.value("http", "HTTP");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.DynamicList, "tcp_path", _("TCP Fake HTTP Path"));
        o.depends("tcp_type", "http");
        o.validate = xjay.validateDirectory;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.DynamicList, "tcp_host", _("TCP Fake HTTP Host"));
        o.depends("tcp_type", "http");
        o.rmempty = false;
        o.modalonly = true;

        // transport tab - kcp settings

        o = ss.taboption('transport', form.Value, "kcp_mtu", _("KCP Maximum Transmission Unit"))
        o.depends("stream_network", "kcp");
        o.datatype = "uinteger";
        o.placeholder = 1350;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "kcp_tti", _("KCP Transmission Time Interval"));
        o.depends("stream_network", "kcp");
        o.datatype = "uinteger";
        o.placeholder = 50;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "kcp_uplinkcapacity", _("KCP Uplink Capacity"));
        o.depends("stream_network", "kcp");
        o.datatype = "uinteger";
        o.placeholder = 5;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "kcp_downlinkcapacity", _("KCP Downlink Capacity"))
        o.depends("stream_network", "kcp");
        o.datatype = "uinteger";
        o.placeholder = 20;
        o.modalonly = true;

        o = ss.taboption('transport', form.Flag, "kcp_congestion", _("KCP Congestion Control"));
        o.depends("stream_network", "kcp");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "kcp_readbuffersize", _("KCP Read Buffer Size"));
        o.depends("stream_network", "kcp");
        o.datatype = "uinteger";
        o.placeholder = 2;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "kcp_writebuffersize", _("KCP Write Buffer Size"));
        o.datatype = "uinteger";
        o.depends("stream_network", "kcp");
        o.placeholder = 2;
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, "kcp_type", _("KCP Fake Header Type"));
        o.depends("stream_network", "kcp");
        o.value("none", "None");
        o.value("srtp", "VideoCall (SRTP)");
        o.value("utp", "BitTorrent (uTP)");
        o.value("wechat-video", "WechatVideo");
        o.value("dtls", "DTLS 1.2");
        o.value("wireguard", "WireGuard");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "kcp_seed", _("KCP Seed"));
        o.depends("stream_network", "kcp");
        o.validate = xjay.validateStingWhitespace;
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        // transport tab - websocket settings

        o = ss.taboption('transport', form.Flag, "ws_acceptproxyprotocol", _("Pass orginal IP and port"));
        o.depends("stream_network", "ws");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "ws_path", _("Websocket Path"));
        o.depends("stream_network", "ws");
        o.validate = xjay.validateDirectory;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "ws_host", _("Websocket Host"));
        o.depends("stream_network", "ws");
        o.datatype= 'hostname';
        o.rmempty = false;
        o.modalonly = true;

        // transport tab - http/2 settings

        o = ss.taboption('transport', form.DynamicList, "http_host", _("HTTP Host"));
        o.depends("stream_network", "h2");
        o.datatype= 'hostname';
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "http_path", _("HTTP Path"));
        o.depends("stream_network", "h2");
        o.validate = xjay.validateDirectory;
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, "http_method", _("HTTP Method"));
        o.depends("stream_network", "h2");
        o.value("PUT", "PUT");
        o.value("GET", "GET");
        o.value("POST", "POST");
        o.optional = true;
        o.modalonly = true;

        // transport tab - quic settings

        o = ss.taboption('transport', form.ListValue, "quic_security", _("QUIC Security"));
        o.depends("stream_network", "quic");
        o.value("none", "none");
        o.value("aes-128-gcm", "aes-128-gcm");
        o.value("chacha20-poly1305", "chacha20-poly1305");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "quic_key", _("QUIC Key"));
        o.depends("stream_network", "quic");
        o.validate = xjay.validateStingWhitespace;
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, "quic_type", _("QUIC Fake Header Type"));
        o.depends("stream_network", "quic");
        o.value("none", _("None"));
        o.value("srtp", _("VideoCall (SRTP)"));
        o.value("utp", _("BitTorrent (uTP)"));
        o.value("wechat-video", _("WechatVideo"));
        o.value("dtls", "DTLS 1.2");
        o.value("wireguard", "WireGuard");
        o.rmempty = false;
        o.modalonly = true;

        // transport tab - domain socket settings

        o = ss.taboption('transport', form.Value, "ds_path", _("Domain Socket Path"));
        o.depends("stream_network", "ds");
        o.validate = xjay.validateDirectory;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.Flag, "ds_abstract", _("Abstract Domain Socket"));
        o.depends("stream_network", "ds");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('transport', form.Flag, "ds_padding", _("Domain Socket Padding"));
        o.depends({"stream_network": "ds", "ds_abstract": "1"});
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        // transport tab - grpc settings

        o = ss.taboption('transport', form.Value, "grpc_servicename", _("gRPC Service Name"));
        o.depends("stream_network", "grpc");
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;
        o.modalonly = true;

        // as blow config options for users
        s.tab('user', _('User'));

        // starts from here is the routing rules table with the ability to add/remove/edit rule

        o = s.taboption("user", form.SectionValue, "user_list", form.GridSection, 'user', _('User List'), _('Add, remove or edit users with user name, password, email and user level.'));
        ss = o.subsection;
        ss.sortable = true;
        ss.anonymous = true;
        ss.addremove = true;
        ss.nodescriptions = true;

        o = ss.option(form.Value, "name", _("User Name"), _("Name of this user without whitespace characters."));
        o.validate = xjay.validateStingWhitespace;
        o.placeholder = 'david';
        o.rmempty = false;

        o = ss.option(form.Value, "password", _("Password"), _("Passowrd of this user without whitespace characters."));
        o.validate = xjay.validateStingWhitespace;
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.option(form.Value, "email", _("Email"), _("Email of this user without whitespace characters."));
        o.validate = xjay.validateStingWhitespace;
        o.placeholder = 'david@example.com';
        o.rmempty = false;

        o = ss.option(form.Value, "level", _("Policy Level"), _('User level for configured policies. This is useful for serving many users, normally it is not needed. See <a href="https://xtls.github.io/config/policy.html#levelpolicyobject">here</a> for help.'));
        o.datatype = 'uinteger';
        o.placeholder = '0';
        o.rmempty = true;

        // as blow config options for fallback
        s.tab('fallback', _('Fallback'));

        // starts from here is the fallback table with the ability to add/remove/edit fallback

        o = s.taboption("fallback", form.SectionValue, "fallbacks", form.GridSection, 'fallback', _('Fallbacks'), _('Add, remove or edit fallback for inbound services.'));
        ss = o.subsection;
        ss.sortable = true;
        ss.anonymous = true;
        ss.addremove = true;
        ss.nodescriptions = true;

        o = ss.option(form.Value, "tag", _("Tag for the fallback"), _('It shall be unique. This will be also used for inbound fallback selection.'));
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;

        o = ss.option(form.Value, "name", _("Server Name"), _("Trying to match TLS SNI."));
        o.validate = xjay.validateStingWhitespace;
        o.placeholder = 'example.com';
        o.modalonly = true;

        o = ss.option(form.Value, 'tls_alpn', _("TLS ALPN"), _('Try to match TLS ALPN negotiation result. Null means any alpn.'));
        o.value("h2", "h2");
        o.value("http/1.1", "http/1.1");
        o.modalonly = true;

        o = ss.option(form.Value, "path", _("HTTP Path"), _('Try to match first http package path.'));
        o.validate = xjay.validateDirectory;
        o.modalonly = true;

        o = ss.option(form.Value, "dest", _("Traffic Destination"), _('The traffic destination after TLS decryption. Could be port number or ipaddr:port or domain:port.'));
        o.placeholder = '8080';
        o.rmempty = false;

        o = ss.option(form.Value, "xver", _("Proxy Version (xver)"), _('Send proxy protocol. Used for forward real IP and port for traffic. Fill 1 or 2. Default 0 means no sending real IP and port.'));
        o.datatype = 'uinteger';
        o.placeholder = '0';
        o.rmempty = true;

        return m.render();
    }

});
