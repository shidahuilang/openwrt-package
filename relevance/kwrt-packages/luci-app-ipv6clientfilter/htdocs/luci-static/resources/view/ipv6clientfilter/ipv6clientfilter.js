'use strict';
'require view';
'require form';
return view.extend({
    render: function () {
        var m,
        s,
        o;
        m = new form.Map('ipv6clientfilter', _('ipv6 client filter'), _('Allow or deny specific clients from accessing ipv6 networks'));
		
        s = m.section(form.NamedSection, 'prefs', 'ipv6clientfilter', _('basic settings'));
		
        o = s.option(form.Flag, 'enabled', _('enable'));
		o.rmempty = false;
        o.default = '0';

        o = s.option(form.ListValue, 'mode', _('mode'), _('blacklist: block clients in the list; whitelist: only allow clients in the list are allowed'));
        o.value('blacklist', _('blacklist'));
        o.value('whitelist', _('whitelist'));
        o.rmempty = false;
		
        s = m.section(form.TableSection, 'client', _('clients'), _('please add some clients'));
        s.anonymous = true;
        s.addremove = true;
		
        o = s.option(form.Flag, 'enabled', _('enable'));
		o.rmempty = false;
		o.width = 50;
        o.default = '1';

		o = s.option(form.Value, 'mac', _('mac'));
		o.rmempty = false;
		o.width = 200;
		o.validate = function (cfg, value) {
			if ( ! /^([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2})$/.test(value)){
				return _('format') + ' xx:xx:xx:xx:xx:xx';
			}
			return true;
		};
        
		o = s.option(form.Value, 'comments', _('comments'));
        o.rmempty = false;
		
        return m.render();
    },
});
