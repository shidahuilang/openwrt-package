'use strict';
'require view';
'require ui';
'require form';
'require rpc';
'require uci';
'require tools.widgets as widgets';
'require tools.github as github';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});	

function getServiceStatus() {
	return L.resolveDefault(callServiceList('kcptun'), {}).then(function (res) {
		var isRunning = false;
		try {
			var instance1 = res['kcptun']['instances'];
			// if instance1 is not null, then kcptun is running
			if (instance1 != null) {
				isRunning = true;
			}
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	var renderHTML = "";
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';

	if (isRunning) {
		renderHTML += String.format(spanTemp, 'green', _("kcptun client"), _("running..."));
	} else {
		renderHTML += String.format(spanTemp, 'red', _("kcptun client"), _("not running..."));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		// uci load kcptun
		return uci.load('kcptun');
	}, 
	render: function() {
		var m, s, o;

		m = new form.Map('kcptun', _('kcptun'));
		m.description = github.luci_desc('kcptun is a Stable & Secure Tunnel Based On KCP with N:M Multiplexing.', 'liudf0716', 'kcptun');

		// add kcptun-client status section and option 
		s = m.section(form.NamedSection, '_status');
		s.anonymous = true;
		s.render = function (section_id) {
			L.Poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then(function(res) {
					var view = document.getElementById("service_status");
					view.innerHTML = renderStatus(res);
				});
			});

			return E('div', { class: 'cbi-map' },
				E('fieldset', { class: 'cbi-section'}, [
					E('p', { id: 'service_status' },
						_('Collecting data ...'))
				])
			);
		}

		s = m.section(form.TypedSection, "client", _("Client Settings"));
		s.anonymous = true;
		// add two tab sections
		// Client Settings and Server Settings file sections
		// Client Settings
		s.tab("client", _("Client Settings"));
		s.tab("server", _("Server Settings"));

		o = s.taboption("client", form.Flag, "enabled", _("Enable"), _("Enable this kcptun client instance"));
		o.rmempty = false;

		o = s.taboption("client", form.Value, "local_port", _("Local Port"), _("Local port to listen"));
		o.datatype = "port";
		o.rmempty = false;

		o = s.taboption("client", form.Value, "server", _("Server Address"), _("Server address to connect"));
		o.datatype = "host";
		o.rmempty = false;

		o = s.taboption("client", form.Value, "server_port", _("Server Port"), _("Server port-range to connect"));
		o.datatype = "portrange";
		o.rmempty = false;

		o = s.taboption("client", form.Value, "key", _("Key"), _("Pre-shared secret between client and server"));
		o.password = true;
		o.rmempty = false;

		o = s.taboption("server", form.DummyValue, "_config", _("Server Command"),
			_("Command to start kcptun server"));
		o.rawhtml = true;
		o.cfgvalue = function(section_id) {
			var server_port = uci.get_first("kcptun", "client", "server_port");
			var key = uci.get_first("kcptun", "client", "key");
			var content = "kcptun-server -l :" + server_port + " -t 127.0.0.1:" + 6441 + " --key \"" + key + "\" &";

			return "<textarea rows='10' cols='50' readonly>" + content + "</textarea>";
		}

		o = s.taboption("server", form.Button, "_copy", _("Copy Command"));
		o.inputtitle = _("Copy the command to clipboard");
		o.inputstyle = "apply";
		o.onclick = function(ev) {
			var textarea = document.querySelector("textarea");
			textarea.select();
			document.execCommand("copy");
			ui.addNotification(null, _("Command copied to clipboard"), "info");
		}
		return m.render();
	}
});
