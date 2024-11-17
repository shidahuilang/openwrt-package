'use strict';
'require view';
'require uci';
'require form';
'require fs';
'require network';
'require tools.widgets as widgets';

return view.extend({
    load: function () {
        return Promise.all([
            uci.load("miniproxy")
        ])
    },

    render: function () {
        var m, s, o;
        m = new form.Map('miniproxy', _('miniproxy'), _('Easy set transparent proxy'));

        s = m.section(form.TypedSection, 'general');
        s.addremove = false;
        s.anonymous = true;

        s.tab('general', _('General Settings'));

        o = s.taboption('general', form.ListValue, 'enabled', _('Enable transparent proxy'))
        o.value("enabled", _("enabled"))
        o.value("disabled", _("disabled"))

        o = s.taboption('general', form.ListValue, 'mode', _('Transparent proxy mode'))
        o.value("ipv4", "ipv4")
        o.value("ipv6", "ipv6")
        o.default = "ipv4"
        o.rmempty = false

        o = s.taboption('general', form.Value, 'port', _('Transparent proxy port'))
        o.datatype = 'port'
        o.placeholder = '1080'

        o = s.taboption('general', form.Value, 'mark', _('Transparent proxy mark'))
        o.datatype = 'range(1, 255)'
        o.placeholder = '255'

        return m.render();
    }
});