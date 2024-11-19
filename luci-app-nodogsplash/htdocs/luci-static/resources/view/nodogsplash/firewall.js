'use strict';
'require form';
'require view';

// Project code format is tabs, not spaces
return view.extend({
	render: function() {
		var m, s, o, i, t;
		m = new form.Map('nodogsplash', _("Firewall Settings"));

		s = m.section(form.TypedSection, 'nodogsplash');
		s.anonymous = true;

		o = s.option(form.DynamicList, "preauthenticated_users", _("Open Port Before Authentication"), _("<br/>allow：<br/>allow tcp port 80<br/>allow udp port 53"))
		o.optional = true

		o = s.option(form.DynamicList, "users_to_router", _("LAN Open Port"), _("<br/>allow：<br/>allow tcp port 80<br/>allow udp port 53"))
		o.optional = true

		o = s.option(form.DynamicList, "authenticated_users", _("Authenticated client isolation settings"), _("<br/>allow：<br/>allow tcp port 80<br/>allow udp port 53<br/>allow all<br/>block：<br/>block to 192.168.0.0/16<br/>192.168.X.1 80 Port Isolation Invalid."))
		o.optional = true

		s = m.section(form.TypedSection, 'nodogsplash', _("Firewall Mask Settings"));
		s.anonymous = true;

		o = s.option(form.Flag, "temp_mask", _("Use specific HEXADECIMAL values to mark packets used by iptables as a bitwise mask."),
				_("<br/> Modify the packet marker hexadecimal mask <br/> without modification if necessary. < br /> if you need visitor equipment to support adbyby, ssr.... See the default package tag. Modify iptables by yourself. <br/>"))

		o = s.option(form.Value, "fw_mark_authenticated", "fw_mark_authenticated");
		o.placeholder = "30000"
		o.datatype="integer"
		o.depends({"temp_mask": "1"})

		o = s.option(form.Value, "fw_mark_trusted", "fw_mark_trusted")
		o.placeholder = "20000"
		o.datatype="integer"
		o.depends({"temp_mask": "1"})

		o = s.option(form.Value, "fw_mark_blocked", "fw_mark_blocked")
		o.placeholder = "10000"
		o.datatype="integer"
		o.depends({"temp_mask": "1"})

		return m.render();
	},
});
