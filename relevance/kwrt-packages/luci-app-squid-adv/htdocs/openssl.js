'use strict';
'require ui';
'require view';
'require uci';
'require form';
'require rpc';
'require tools.widgets as widgets';

return view.extend({
	cert_valid: rpc.declare({
		object: 'luci.squid-adv',
		method: 'cert_info',
	}),
	get_ipinfo: rpc.declare({
		object: 'luci.squid-adv',
		method: 'ip_info',
	}),
	generate: rpc.declare({
		object: 'luci.squid-adv',
		method: 'generate',
        params: [ 'bits', 'days', 'country', 'state', 'locality', 'organization' ],
	}),

	// Loading function:
    load: function () {
        return Promise.all([
            this.cert_valid(),
        ]);
    },

	// Rendering function:
	render: function(data) {
		var s, o, m, t;
		m = new form.Map('squid', _('OpenSSL Certificate'));
		this.valid = data[0].valid;

		if (this.valid) {
			s = m.section(form.TypedSection, 'squid', _("Certificate Valid Period"));
			s.anonymous = true;

			o = s.option(form.Value, "_notBefore", _("Current Certificate Valid Starting:"), _("ISO-8601 formatted date: YY-MM-DD HH:MM:SS"))
			o.cfgvalue = function() { return data[0].notBefore != undefined ? data[0].notBefore : 'Invalid'; }
			o.write = null;
			o.readonly = true;

			o = s.option(form.Value, "_notAfter", _("Current Certificate Not Valid After:"), _("ISO-8601 formatted date: YY-MM-DD HH:MM:SS"))
			o.cfgvalue = function() { return data[0].notAfter != undefined ? data[0].notAfter : 'Invalid'; }
			o.write = null;
			o.readonly = true;
		}

		s = m.section(form.TypedSection, 'squid', _("Certificate Settings"));
		s.anonymous = true;

		o = s.option(form.ListValue, "bits", _("RSA Key Bit Size:"))
		o.value("4096", "4096 bits (" + _("Best") + ")")
		o.value("2048", "2048 bits (" + _("Better") + ")")
		o.value("1024", "1024 bits (" + _("Not Recommended") + ")")
		o.value("512", "512 bits (" + _("Not Recommended") + ")")
		o.write = null;
		o.rmempty = false
		o.cfgvalue = function() { return data[0].bits != undefined ? data[0].bits : '4096'; }

		o = s.option(form.Value, "days", _("Days The Certificate Is Good For:"))
		o.default = "3650"
		o.datatype = 'integer';
		o.cfgvalue = function() { if (data[0].days != undefined) { return data[0].days; } }
		o.write = null;
		o.validate = function(section_id, value) { return value > 0 ? true : _("Number of days cannot be negative!"); } 
		
		o = s.option(form.Value, "countryName", _("Country Name:"))
		o.cfgvalue = function() { return data[0].countryName != undefined ? data[0].countryName : 'XX'; }
		o.write = null;
		o.validate = function(section_id, value) { return value.length == 2 ? true : _("Must be a two-letter country code!"); } 

		o = s.option(form.Value, "stateOrProvinceName", _("State Or Province Name:"))
		o.cfgvalue = function() { return data[0].stateOrProvinceName != undefined ? data[0].stateOrProvinceName : 'Unspecified'; }
		o.write = null;

		o = s.option(form.Value, "localityName", _("Locality Name:"))
		o.default = data[0].localityName != undefined ? data[0].localityName : 'Unspecified';
		o.cfgvalue = function() { return null; }
		o.write = null;

		o = s.option(form.Value, "organizationName", _("Organization Name:"))
		o.cfgvalue = function() { return data[0].organizationName != undefined ? data[0].organizationName : 'OpenWrt Router'; }
		o.write = null;

		return m.render();
	},

	regenerate_cert: function() {
		if (confirm( _("Regenerating the certificate will overwrite the current OpenSSL certificate, and will require installing the new certificate on all devices.\n\nAre you SURE you want to do this?") )) {
			return this.generate_cert();
		}
	},
	
	generate_cert: function() {
		// Gather information:
		var bits = document.getElementById("widget.cbid.squid.squid.bits").value;
		var days = document.getElementById("widget.cbid.squid.squid.days").value;
		var country = document.getElementById("widget.cbid.squid.squid.countryName").value;
		var state = document.getElementById("widget.cbid.squid.squid.stateOrProvinceName").value;
		var locality = document.getElementById("widget.cbid.squid.squid.localityName").value;
		var organization = document.getElementById("widget.cbid.squid.squid.organizationName").value;

		// Create a promise for the OpenSSL Certificate Generation task:
		var tasks = [
			this.generate( bits, days, country, state, locality, organization ),
		];
		return Promise.all(tasks).then(function() {
			classes.ui.changes.apply(false);
		});
	},

	populate: function() {
		return Promise.all([ this.get_ipinfo() ]).then(function(data) {
			console.log(data);
			document.getElementById("widget.cbid.squid.squid.countryName").value = data[0].country != undefined ? data[0].country : 'XX';
			document.getElementById("widget.cbid.squid.squid.stateOrProvinceName").value = data[0].region != undefined ? data[0].region : 'Unspecified'; 
			document.getElementById("widget.cbid.squid.squid.localityName").value = data[0].city != undefined ? data[0].city : 'Unspecified';
		});
	},

	addFooter: function() {
		return E('div', { 'class': 'cbi-page-actions' }, [
			this.valid ? 
				E('button', {'class': 'cbi-button cbi-button-positive', 'click': L.ui.createHandlerFn(this, 'regenerate_cert')}, [ _('Regenerate Certificate'), ' ' ]) : 
				E('button', {'class': 'cbi-button cbi-button-positive', 'click': L.ui.createHandlerFn(this, 'generate_cert')}, [ _('Generate Certificate'), ' ' ]),
			E('button', {'class': 'cbi-button cbi-button-negative', 'click': L.ui.createHandlerFn(this, 'populate')}, [ _('Populate Fields') ])
		]);
	}
})
