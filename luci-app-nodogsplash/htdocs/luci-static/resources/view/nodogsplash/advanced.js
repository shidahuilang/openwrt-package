'use strict';
'require form';
'require ui';
'require view';

// Project code format is tabs, not spaces
return view.extend({
	render: function() {
		var m, s, o, i, t;
		m = new form.Map('nodogsplash', _("Advanced Settings"));

		s = m.section(form.TypedSection, 'nodogsplash');
		s.anonymous = true;

		o = s.option(form.Flag, 'fwhook_enabled', _("Restart nodogsplash when the firewall restarts."), _("Enabled by default"));
		o.rmempty = false;
		o.optional = false;

		o = s.option(form.Value, 'gatewayport', _('Gateway Port Number'));
		o.default = "2050"
		o.rmempty = false;
		o.datatype = "integer"

		o = s.option(form.Value, 'webroot', _('Web folder'))
		o.placeholder = "/etc/nodogsplash/htdocs"

		o = s.option(form.Value, 'maxclients', _('Maximum number of users'))
		o.placeholder = "250"
		o.datatype = "integer"

		o = s.option(form.Value, "preauth", _("Dynamic Web Page served by NDS"), _("The shell script will be invoked for authentication. <br/> Refer here for more information:") + " <a href=\"https://nodogsplash.readthedocs.io/en/latest/customize.html#the-splash-page\" target=\"blank\">NoDogSplash Wiki: The Splash Page</a>")
		o.placeholder = "/usr/lib/nodogsplash/login.sh"
		o.optional = true

		o = s.option(form.Value, "binauth", _("Shell Script Path"), _("The shell script will be invoked for authentication. <br/> Refer here for more information:") + " <a href=\"https://nodogsplash.readthedocs.io/en/latest/binauth.html\" target=\"blank\">NoDogSplash Wiki: BinAuth Option</a>")
		o.placeholder = "/bin/myauth.sh"
		o.optional = true

		o = s.option(form.ListValue, 'gatewayinterface', _('Debug Level'));
		o.value("0", _("Level 0: Silent"));
		o.value("1", _("Level 1: LOG_ERR, LOG_EMERG, LOG_WARNING and LOG_NOTICE"))
		o.value("2", _("Level 2: Level 1 + LOG_INFO"))
		o.value("3", _("Level 3: Level 2 + LOG_DEBUG"))
		o.rmempty = false;

		s = m.section(form.TypedSection, 'nodogsplash', _("Forwarding Authentication Service") + " (FAS)");
		s.anonymous = true;

		o = s.option(form.Value, "fasremoteip ", _("FAS Remote IP Address"))
		o.optional = true

		o = s.option(form.Value, "fasport", _("FAS Port Number Used"), _("if FAS is running locally (ie fasremoteip is NOT set), port 80 cannot be used.<br/>Typical Remote Shared Hosting Example:80.Typical Locally Hosted example (ie fasremoteip not set):2080.<br/>if Enable username/emailaddress login.fasport must be set to the same value as gatewayport (default = 2050)"))
		o.optional = true
		o.datatype = "integer"

		o = s.option(form.Value, "faspath", _("FAS Page Address"), _("The path of login page under Web root directory, ex: '/nodog/fas.php'<br/>If it is a user name login authentication method, ex: '/nodogsplash_preauth/'"))
		o.optional = true

		o = s.option(form.Flag, "fas_secure_enabled", _("FAS Client token encryption"), _("If unchecked, the client token is sent to the FAS in clear text in the query string of the."))
		o.optional = true
		o.placeholder = "0"
		o.datatype="integer"

		return m.render();
	},
});
