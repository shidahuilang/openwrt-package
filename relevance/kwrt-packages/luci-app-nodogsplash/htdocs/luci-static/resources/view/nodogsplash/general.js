'use strict';
'require form';
'require ui';
'require view';
'require network';

// Project code format is tabs, not spaces
return view.extend({
	load: function() {
		return Promise.all([
			network.getDevices(),
		]);
	},

	render: function(data) {
		var netDevs = data[0];
		var m, s, o, i, t;
		m = new form.Map('nodogsplash', _("General Settings"));

		s = m.section(form.TypedSection, 'nodogsplash');
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('Enabled'));
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.ListValue, 'gatewayinterface', _('Interface Name'));
		o.default = netDevs[0].getName();
		for (var i = 0; i < netDevs.length; i++) {
			t = netDevs[i].getName();
			if (t != "lo" && t.substring(0,3) != "ifb" && t.substring(0,5) != "radio") {
				o.value(t);
			}
			if (t == "br-lan") {
				o.default = t;
			}
		}
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Value, 'gatewayname', _('Authentication Page Name'), _("Name displayed on portal page."));
		o.rmempty = false;

		o = s.option(form.Value, 'preauthidletimeout', _("Equipment Disconnection Retention Authentication (sub)"));
		o.placeholder = "30"
		o.rmempty = false;
		o.datatype = "integer"

		o = s.option(form.Value, 'authidletimeout', _("Time of equipment re-certification (minutes)"))
		o.placeholder = "120"
		o.rmempty = false;
		o.datatype = "integer"

		o = s.option(form.Value, 'sessiontimeout', _("Portal page timeout (seconds)"))
		o.placeholder = "1200"
		o.rmempty = false;
		o.datatype = "integer"

		o = s.option(form.Value, 'checkinterval', _("Check the authentication status interval (seconds)"))
		o.placeholder = "600"
		o.rmempty = false;
		o.datatype = "integer"

		return m.render();
	},
});
