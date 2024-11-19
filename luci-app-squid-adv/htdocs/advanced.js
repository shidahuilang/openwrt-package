'use strict';
'require fs';
'require view';
'require form';

return view.extend({
	// Rendering function:
	render: function(data) {
		var s, o, m, t;
		m = new form.Map('squid', _('Advanced Settings'));

		s = m.section(form.TypedSection, 'squid');
		s.anonymous = true;

		o = s.option(form.TextValue, "squid_config_file")
		o.wrap = "off"
		o.rows = 25
		o.rmempty = false
		o.cfgvalue = function() {
			return fs.exec_direct("/usr/libexec/rpcd/luci.squid-adv", [ "config", "read" ]);
		}
		o.write = function() {
			return Promise.all([
				fs.write( "/tmp/luci-app-squid-adv.data", document.getElementById("widget.cbid.squid.squid.squid_config_file").value ),
				fs.exec_direct("/usr/libexec/rpcd/luci.squid-adv", [ "config", "move" ]),
			]);
		}

		return m.render();
	},
})
