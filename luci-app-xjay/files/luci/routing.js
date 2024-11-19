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
        m = new form.Map('xjay', _('Routing'), _('Routing settings for xjay.'));

        s = m.section(form.TypedSection, 'routing');
        s.addremove = false;
        s.anonymous = true;

        o = s.option(form.ListValue, 'domainstrategy', _('Routing Domain Strategy'), _("Domain resolution strategy when matching domain against rules."));
        o.value("AsIs", "AsIs");
        o.value("IPIfNonMatch", "IPIfNonMatch");
        o.value("IPOnDemand", "IPOnDemand");
        o.rmempty = false;

        o = s.option(form.ListValue, "domainmatcher", _("Domain Matcher"), _("The method used to match the domains"));
        o.value("hybrid", "Hybrid mode (new)");
        o.value("linear", "Linear mode (legacy)");
        o.optional = true;

        o = s.option(form.DynamicList, "service_port", _("Service Ports"), _("Source ports from WAN connection of this device will be bypassed. This is useful when you want to access services from outside."));
        o.datatype = "port";
        o.rmempty = true;

        // starts from here is the routing rules table with the ability to add/remove/edit rule

        o = s.option(form.SectionValue, "routing_rules", form.GridSection, 'routing_rule', _('Routing Rules'), _('Rules with specific routing for different matching domains. See <a href="https://xtls.github.io/config/routing.html">Routing</a> for details.'));
        ss = o.subsection;
        ss.sortable = true;
        ss.anonymous = true;
        ss.addremove = true;
        ss.nodescriptions = true;

        // general options for routing rule

        o = ss.option(form.DummyValue, '_generalconfig');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>General Options for Routing Rule</strong>');
        };

        o = ss.option(form.Value, "tag", _("Tag"), _("Alias name for this rule."));
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;

        o = ss.option(form.ListValue, "rule_domainmatcher", _("Domain Matcher"), _("The method used to match the domains"));
        o.value("hybrid", "Hybrid mode (new)");
        o.value("linear", "Linear mode (legacy)");
        o.optional = true;
        o.modalonly = true;

        o = ss.option(form.Value, "rule_outboundtag", _("Outbound Tag"), _("One outbound tag for all the matched traffic."));
        o.validate = xjay.validateStingWhitespace;
        o.rmempty = false;
        o.value("direct");
        o.value("blackhole_outbound");
        o.value("dns_outbound");
        for (var v of uci.sections(config_data, "outbound_server")) {
            o.value(v.tag);
        }

        o = ss.option(form.ListValue, "dns_server", _("DNS Server"),  _("Query domains using this DNS server."));
        o.optional = true;
        for (var v of uci.sections(config_data, "dns_server")) {
            o.value(v.tag);
        }

        // matching conditions for routing rule

        o = ss.option(form.DummyValue, '_matchingcondition');
        o.rawhtml = true;
        o.modalonly = true;
        o.cfgvalue = function(section_id) {
            return _('<strong>Matching Conditions for Routing Rule</strong>');
        };

        o = ss.option(form.DynamicList, "rule_domain", _("Domains"), _('Specify rules like <code>geosite:cn</code> or <code>domain:bilibili.com</code>. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'));
        o.validate = xjay.validateRoutingDomains;
        o.modalonly = true;

        o = ss.option(form.DynamicList, "rule_ip",_("Destination IP Address"),  _("Destination IP address to be matched for this rule. Could be IPv4 or IPv6."));
        o.validate = xjay.validateRoutingIP;
        o.modalonly = true;

        o = ss.option(form.DynamicList, "rule_port", _("Destination Port"), _("Destination port to be matched for this rule."));
        o.datatype = "or(port, portrange)";
        o.modalonly = true;

        o = ss.option(form.DynamicList, "rule_source", _("Source IP Address"), _("Source IP address to be matched for this rule. Could be IPv4 or IPv6."));
        o.validate = xjay.validateRoutingIP;
        o.modalonly = true;

        o = ss.option(form.DynamicList, "rule_sourceport", _("Source Port"), _("Source port to be matched for this rule."));
        o.datatype = "or(port, portrange)";
        o.modalonly = true;

        o = ss.option(form.MultiValue, "rule_network", _("Network Type"), _("Network type to be matched for this rule."));
        o.value("tcp", "TCP");
        o.value("udp", "UDP");
        o.modalonly = true;

        o = ss.option(form.DynamicList, "rule_user", _("User Email"), _("User email address to be matched for this rule."));
        o.modalonly = true;

        o = ss.option(form.DynamicList, "rule_inboundtag", _("Inbound Tag"), _("Inbound tags to be matched for this rule."));
        o.validate = xjay.validateStingWhitespace;
        o.modalonly = true;
        for (var v of uci.sections(config_data, "inbound_service")) {
            o.value(v.tag);
        }

        o = ss.option(form.MultiValue, "rule_protocol", _("Protocol Type"), _("Protocol types to be matched for this rule. Need to activate inbound sniffing."));
        o.value("http", "HTTP protocol");
        o.value("tls", "TLS protocol");
        o.value("bittorrent", "BitTorrent protocol");
        o.modalonly = true;

        o = ss.option(form.DynamicList, "rule_attrs", _("Attribute Script"), _('A script to detect the traffic attributes. If return yes, the match the rule. See <a href="https://xtls.github.io/config/dns.html#dnsobject">documentation</a> for details.'));
        o.modalonly = true;

        return m.render();
    }

});
