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
        m=new form.Map('xjay', _('Outbound'), _('Outbound settings for xjay.'));

        s = m.section(form.TypedSection, 'outbound');
        s.addremove = false;
        s.anonymous = true;

        // as blow are some general config options for outbound servers

        o = s.option(form.ListValue, "default_outbound", _("Default outbound"),  _("All the connections that do not match any routing rules will forwarded to this outbound server."));
        o.datatype = "string";
        o.optional = true;
        o.value('direct', 'direct (pre-defined)');
        o.value('blackhole', 'blackhole (pre-defined)');
        for (var v of uci.sections(config_data, "outbound_server")) {
            o.value(v.tag);
        }

        o = s.option(form.Value, 'sockopt_mark', _('Socket Mark Number'), _('Avoid proxy loopback problems with local (gateway) traffic. Set a number which is not used by other firewall rules.'));
        o.datatype = 'range(1, 255)';
        o.placeholder = '255';

        // starts from here is the outbound servers table with the ability to add/remove/edit server

        o = s.option(form.SectionValue, "outbound_servers", form.GridSection, 'outbound_server', _('Xray Servers'), _("Servers are referenced by index (order in the following list). Deleting servers may result in changes of upstream servers actually used by proxy and bridge."));
        ss = o.subsection;
        ss.sortable = true;
        ss.anonymous = true;
        ss.addremove = true;
        ss.nodescriptions = true;

        // general tab of the server configuration popup

        ss.tab('general', _('General Settings'));

        o = ss.taboption('general', form.Value, "tag", _("Tag (Must be unique)"));
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;

        o = ss.taboption('general', form.Value, "address", _("Server Address"));
        o.datatype = 'host';
        o.placeholder = 'example.com';
        o.rmempty = false;

        o = ss.taboption('general', form.Value, "port", _("Server Port"));
        o.datatype = 'port';
        o.placeholder = '443';
        o.rmempty = false;

        o = ss.taboption('general', form.Value, 'sendthrough', _('Data sending address'));
        o.datatype = 'host';
        o.placeholder = '0.0.0.0';
        o.modalonly = true;

        // protocol tab of the server configuration popup

        ss.tab('protocol', _('Protocol Settings'));

        o = ss.taboption('protocol', form.DummyValue, '_selectconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Porotol and Security Selection</strong>');
        };

        o = ss.taboption('protocol', form.ListValue, "protocol", _("Protocol"));
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

        // protocol tab - http config options

        o = ss.taboption('protocol', form.Value, "http_user", _("HTTP User Name"));
        o.depends("protocol", "http");
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "http_pass", _("HTTP Password"));
        o.depends("protocol", "http");
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        // protocol tab - shadowsocks config options

        o = ss.taboption('protocol', form.ListValue, "ss_method", _("Shadowsocks Encrypt Method"));
        o.depends("protocol", "shadowsocks");
        o.value("none", "none");
        o.value("aes-256-gcm", "aes-256-gcm");
        o.value("aes-128-gcm", "aes-128-gcm");
        o.value("chacha20-poly1305", "chacha20-poly1305");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "ss_password", _("Shadowsocks password"));
        o.depends("protocol", "shadowsocks");
        o.validate = xjay.validateStingWhitespace;
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Flag, 'ss_uot', _('Enable udp over tcp'));
        o.depends("protocol", "shadowsocks");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "ss_email", _("User Email Address"));
        o.depends("protocol", "shadowsocks");
        o.placeholder = 'david@example.com';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "ss_level", _("User Level"));
        o.depends("protocol", "shadowsocks");
        o.placeholder = '0';
        o.modalonly = true;

        // protocol tab - socks config options

        o = ss.taboption('protocol', form.Value, "socks_user", _("Socks User Name"));
        o.depends("protocol", "socks");
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "socks_pass", _("Socks Password"));
        o.depends("protocol", "socks");
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "socks_level", _("User Level"));
        o.depends("protocol", "socks");
        o.placeholder = '0';
        o.modalonly = true;

        // protocol tab - trojan config options

        o = ss.taboption('protocol', form.Value, "trojan_password", _("Trojan password"));
        o.depends("protocol", "trojan");
        o.validate = xjay.validateStingWhitespace;
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "trojan_email", _("User Email Address"));
        o.depends("protocol", "trojan");
        o.placeholder = 'david@example.com';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "trojan_level", _("User Level"));
        o.depends("protocol", "trojan");
        o.placeholder = '0';
        o.modalonly = true;

        // protocol tab - vless config options

        o = ss.taboption('protocol', form.Value, "vless_id", _("Vless User ID"));
        o.depends("protocol", "vless");
        o.validate = xjay.validateStingWhitespace;
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.ListValue, "vless_encryption", _("Vless Encrypt Method"));
        o.depends("protocol", "vless");
        o.value("none", "none");
        o.rmempty = false;
        o.modalonly = true;

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

        o = ss.taboption('protocol', form.Value, "vless_level", _("User Level"));
        o.depends("protocol", "vless");
        o.placeholder = '0';
        o.modalonly = true;

        // protocol tab - vmess config options

        o = ss.taboption('protocol', form.Value, "vmess_id", _("Vmess User ID"));
        o.depends("protocol", "vmess");
        o.validate = xjay.validateStingWhitespace;
        o.password = true;
        o.rmempty = false;
        o.modalonly = true;

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

        o = ss.taboption('protocol', form.ListValue, "vmess_security", _("Vmess Encrypt Method"));
        o.depends("protocol", "vmess");
        o.value("none", "none");
        o.value("auto", "auto");
        o.value("aes-128-gcm", "aes-128-gcm");
        o.value("chacha20-poly1305", "chacha20-poly1305");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, "vmess_level", _("User Level"));
        o.depends("protocol", "vmess");
        o.placeholder = '0';
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

        o = ss.taboption('protocol', form.Value, 'tls_servername', _('TLS Server Name'));
        o.datatype= 'hostname';
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Flag, 'tls_allowinsecure', _('TLS Allow Insecure'));
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

        o = ss.taboption('protocol', form.Flag, 'tls_disablesystemroot', _('Disable System CA'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.Flag, 'tls_disablesystemroot', _('Enable Session Resumption'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('protocol', form.ListValue, 'tls_fingerprint', _('TLS Fingerprint'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
        o.value("", "(not set)");
        o.value("chrome", "Chrome");
        o.value("firefox", "Firefox");
        o.value("safari", "Safari");
        o.value("ios", "iOS");
        o.value("android", "Android");
        o.value("edge", "Edge");
        o.value("random", "Random");
        o.value("randomized", "Randomize");
        o.modalonly = true;

        o = ss.taboption('protocol', form.DynamicList, 'tls_pinnedpeercertificatechainsha256', _('Remote Cert Chain SHA256'));
        o.depends('stream_security', "tls");
        o.depends('stream_security', "xtls");
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

        o = ss.taboption('protocol', form.Value, 'reality_servername', _('Server Name'));
        o.depends('stream_security', "reality");
        o.datatype= 'hostname';
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.ListValue, 'reality_fingerprint', _('Fingerprint'));
        o.depends('stream_security', "reality");
        o.value("", "(not set)");
        o.value("chrome", "Chrome");
        o.value("firefox", "Firefox");
        o.value("safari", "Safari");
        o.value("ios", "iOS");
        o.value("android", "Android");
        o.value("edge", "Edge");
        o.value("random", "Random");
        o.value("randomized", "Randomize");
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_shortid', _('Short ID'));
        o.depends('stream_security', "reality");
        o.validate = xjay.validateShortID;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_publickey', _('Public Key'));
        o.depends('stream_security', "reality");
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('protocol', form.Value, 'reality_spiderx', _('Spider Path'));
        o.depends('stream_security', "reality");
        o.modalonly = true;

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
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, 'sockopt_domainstrategy', _('Domain Query Strategy'));
        o.value("UseIP");
        o.value("UseIPv4");
        o.value("UseIPv6");
        o.optional = true;
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, 'sockopt_dialerproxy', _('Dialer Proxy'));
        o.validate = xjay.validateStingWhitespace;
        o.placeholder = 'another_outbound_tag';
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, 'sockopt_interface', _('Outbound Interface'));
        o.validate = xjay.validateStingWhitespace;
        o.placeholder = 'eth0';
        o.modalonly = true;

        // transport tab - network types

        o = ss.taboption('transport', form.DummyValue, '_networktypeoptconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Configuration Options for Network</strong>');
        };

        o = ss.taboption('transport', form.ListValue, 'stream_network', _('Transport'));
        o.value("tcp", "TCP");
        o.value("kcp", "mKCP");
        o.value("ws", "WebSocket");
        o.value("h2", "HTTP/2");
        o.value("quic", "QUIC");
        o.value("ds", "Domain Socket");
        o.value("grpc", "gRPC");
        o.rmempty = false;

        // transport tab - tcp settings

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

        o = ss.taboption('transport', form.Value, "http_readidletimeout", _("HTTP Timeout Before Health Check"));
        o.depends("stream_network", "h2");
        o.datatype = "uinteger";
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "http_healthchecktimeout", _("HTTP Health Check Timeout"));
        o.depends("stream_network", "h2");
        o.datatype = "uinteger";
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

        // transport tab - grpc settings

        o = ss.taboption('transport', form.Value, "grpc_servicename", _("gRPC Service Name"));
        o.depends("stream_network", "grpc");
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;
        o.modalonly = true;

        o = ss.taboption('transport', form.Flag, "grpc_multimode", _("gRPC Multi Mode"));
        o.depends("stream_network", "grpc");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;
        o.optional = true;

        o = ss.taboption('transport', form.Value, "grpc_idletimeout", _("gRPC Idle Timeout"));
        o.depends("stream_network", "grpc");
        o.datatype = 'integer';
        o.placeholder = 10;
        o.modalonly = true;
        o.optional = true;

        o = ss.taboption('transport', form.Value, "grpc_healthchecktimeout", _("gRPC Health Check Timeout"));
        o.depends("stream_network", "grpc");
        o.datatype = 'integer';
        o.placeholder = 20;
        o.modalonly = true;
        o.optional = true;

        o = ss.taboption('transport', form.Flag, "grpc_permitwithoutstream", _("gRPC Permit Without Stream"));
        o.depends("stream_network", "grpc");
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;
        o.optional = true;

        o = ss.taboption('transport', form.Value, "grpc_initialwindownsize", _("gRPC Initial Windows Size"), _("If the value 0 then the function will be disabled. If the value is greater than 65535, then dynamic window will be disabled. Set to 524288 if you're using cloudflare CDN, this could avoid Cloudflare sending h2 GOAWAY to end the connection."));
        o.depends("stream_network", "grpc");
        o.datatype = 'integer';
        o.placeholder = 0;
        o.modalonly = true;
        o.optional = true;

        o = ss.taboption('transport', form.Value, "grpc_useragent", _("gRPC User Agent"));
        o.depends("stream_network", "grpc");
        o.rmempty = false;
        o.modalonly = true;
        o.optional = true;

        // transport tab - mux settings

        o = ss.taboption('transport', form.Flag, "mux_enabled", _("Enable Mux"));
        o.enabled = 'true';
        o.disabled = 'false';
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "mux_concurrency", _("Maximum concurrent TCP connections"), _("The number means maximum child connections in a TCP connection. Range from 1 to 1024. If set -1, then it will not use mux to do TCP connection."));
        o.depends("mux_enabled", "true");
        o.datatype = 'integer';
        o.placeholder = '16';
        o.modalonly = true;

        o = ss.taboption('transport', form.Value, "mux_xudpconcurrency", _("Maximum concurrent UDP connections"), _("Use XUDP tunel to proxy UDP traffic. The number means maximum UDP over TCP concurrent connections. Range from 1 to 1024. If set 0, keep it blank set as 0, will use the same TCP connection. If set -1, then it will not use mux to do UDP connection."));
        o.depends("mux_enabled", "true");
        o.datatype = 'integer';
        o.placeholder = '16';
        o.modalonly = true;

        o = ss.taboption('transport', form.ListValue, "mux_xudpproxyudp443", _("QUIC UDP proxy mode"), _("Control the behavior of handling QUIC(UDP/443) traffic."));
        o.depends("mux_enabled", "true");
        o.value("reject", "reject - fallback to TCP HTTP/2");
        o.value("allow", "allow - go through mux connection");
        o.value("skip", "skip - not use mux for quic");
        o.optional = true;
        o.modalonly = true;

        return m.render();
    }

});
