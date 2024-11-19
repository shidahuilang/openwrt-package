'use strict';
'require view';
'require form';
'require xjay';

return view.extend({

    render:function(){
        var m, s, o, ss;
        m = new form.Map('xjay', _('DNS'), _('DNS settings for xjay.'));

        s = m.section(form.TypedSection, 'dns');
        s.addremove = false;
        s.anonymous = true;

        o = s.option(form.ListValue, 'querystrategy', _('DNS Query Strategy'), _("To query only IPv4 or IPv6 or both."));
        o.value("UseIP");
        o.value("UseIPv4");
        o.value("UseIPv6");
        o.optional = true;

        o = s.option(form.Flag, 'disablecache', _('DNS Cache'), _('Enable DNS cache may speed up dns resolving speed.'));
        o.enabled = 'false';
        o.disabled = 'true';

        o = s.option(form.Flag, 'disablefallback', _('Disable Fallback Query'), _('Stop failed dns query to query using fallback servers again.'));
        o.enabled = 'true';
        o.disabled = 'false';

        o = s.option(form.Flag, 'disablefallbackifmatch', _('Disable Fallback If Match'), _('Disable fallback query when dns query match one domain in the DNS domain list.'));
        o.enabled = 'true';
        o.disabled = 'false';

        o = s.option(form.Value, "clientip", _("Client IP Address"));
        o.datatype = 'ipaddr';
        o.placeholder = '124.23.35.22';

        o = s.option(form.Value, "tag", _("Tag"), _('For routing rules to match the traffic sent by built-in DNS.'));
        o.placeholder = 'dns_inbound';

        o = s.option(form.DynamicList, "host", _("Hosts"), _("Set static domains. Queries of these domains will get the IP address mapped to them"));
        o.validate = xjay.validateServerSpec;
        o.placeholder = "/dns.google/8.8.8.8";
        o.rmempty = true;

        o = s.option(form.DynamicList, 'alt_dns', _('Alternative DNS Servers'), _("Using these DNS server to query the domains that doen't match any other dns server domains."));
        o.validate = xjay.validateDNS;
        o.placeholder = "8.8.8.8";
        o.rmempty = true;

        o = s.option(form.SectionValue, "dns_servers", form.GridSection, 'dns_server', _('DNS Servers'), _('DNS servers for rule based queries. Only domains that server domain list will using that DNS server to query. See <a href="https://xtls.github.io/config/dns.html#dns-%E6%9C%8D%E5%8A%A1%E5%99%A8">Built-in DNS server</a> for details.'));
        ss = o.subsection;
        ss.sortable = false;
        ss.anonymous = true;
        ss.addremove = true;
        ss.nodescriptions = true;

        o = ss.option(form.Value, "tag", _("Tag"), _("Alias name for this dns server."));
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;

        o = ss.option(form.ListValue, 'querystrategy', _('DNS Query Strategy'), _("To query only IPv4 or IPv6 or both."));
        o.value("UseIP");
        o.value("UseIPv4");
        o.value("UseIPv6");
        o.optional = true;

        o = ss.option(form.Value, "server_address",_("Server IP Address"),  _("Valid server could be like 8.8.8.8 or 8.8.8.8:5353 or https://dns.google/dns-query or https+local://dns.google/dns-query or tcp://8.8.8.8:53 or tcp+local://8.8.8.8:53 or localhost."));
        o.validate = xjay.validateDNS;
        o.placeholder = "8.8.8.8";
        o.rmempty = false;

        o = ss.option(form.Value, "server_port", _("Server Port"), _("DNS server port to query domains."));
        o.datatype = "port"
        o.placeholder = '53'
        o.rmempty = false;

        o = ss.option(form.DynamicList, "server_domain", _("Domains"), _('Specify rules like <code>geosite:cn</code> or <code>domain:bilibili.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'));
        o.validate = xjay.validateRoutingDomains;
        o.placeholder = 'geosite:google';
        o.datatype = "string";
        o.modalonly = true;

        o = ss.option(form.DynamicList, "server_expectedip", _("Expected IP Address"), _('Specify IP address so that only query result that matches on of the IP addresses will be returned.'));
        o.validate = xjay.validateRoutingIP;
        o.placeholder = 'geoip:cn';
        o.modalonly = true;

        o = ss.option(form.DynamicList, "server_clientip", _("Client IP Address"));
        o.datatype = 'ipaddr';
        o.placeholder = '124.23.35.22';
        o.modalonly = true;

        return m.render();
    }

});
