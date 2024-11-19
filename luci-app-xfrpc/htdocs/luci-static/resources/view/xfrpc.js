'use strict';
'require view';
'require ui';
'require form';
'require rpc';
'require dom';
'require tools.widgets as widgets';
'require tools.github as github';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

var callInstaLoader = rpc.declare({
	object: 'luci',
	method: 'callInstaLoader',
	params: ['action', 'param', 'name'],
	expect: { result : "OK" }
});


function getServiceStatus() {
	return L.resolveDefault(callServiceList('xfrpc'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['xfrpc']['instances']['instance1']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	var renderHTML = "";
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';

	if (isRunning) {
		renderHTML += String.format(spanTemp, 'green', _("xfrpc client"), _("running..."));
	} else {
		renderHTML += String.format(spanTemp, 'red', _("xfprc client"), _("not running..."));
	}

	return renderHTML;
}

function executePluginAction(id, ev) {
	var name = id;
	var selectedRow = ev.target.parentElement.parentElement.parentElement.parentElement;
	var pluginName = selectedRow.querySelector('td:nth-child(1)').innerText;
	var pluginAction = selectedRow.querySelector('td:nth-child(2)').innerText;
	var pluginParam = selectedRow.querySelector('td:nth-child(3)').innerText;
	console.log(name + " " + pluginName + " " + pluginAction + " " + pluginParam);
	if (pluginName == "instaloader") {
		if (pluginAction == "download") {
			if (pluginParam == "") {
				alert("please input profile url to download");
			} else {
				callInstaLoader('download', pluginParam, name).then(function (res) {
					// parse json res
					var jsonRes = JSON.parse(res);
					if (jsonRes["status"] == "ok") {
						alert("start download video");
					} else {
						alert("download video failed");
					}
				});
			}
		} else if (pluginAction == "stop") {
			callInstaLoader('stop', '', name).then(function (res) {
				var jsonRes = JSON.parse(res);
				if (jsonRes["status"] == "ok") {
					alert("stop download video");
				} else {
					alert("stop download video failed");
				}
			});
		}
	} else if (pluginName == "youtubedl") {
		if (pluginAction == "download") {
			if (pluginParam == "") {
				alert("please input video url to download");
			} else {
				callInstaLoader('download', pluginParam, name).then(function (res) {
					var jsonRes = JSON.parse(res);
					if (jsonRes["status"] == "ok") {
						alert("start download video");
					} else {
						alert("download video failed");
					}
				});
			}
		}
	} else {
		alert("not support plugin");
	}
}

return view.extend({
	render: function() {
		var m, s, o, ss;
		var web_proxy = ['http', 'https'];

		m = new form.Map('xfrpc', _('xfrpc'));
		m.description = github.desc(
			'xfrpc is a c language frp client for frps.', 'liudf0716', 'xfrpc');
		
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

		s = m.section(form.NamedSection, 'common', 'xfrpc');
		s.dynamic = true;

		s.tab('common', _('General Settings'));
		s.tab('tcp', _('TCP Proxy'));
		s.tab('http', _('HTTP Proxy'));
		s.tab('https', _('HTTPS Proxy'));
		s.tab('socks5', _('SOCKS5 Proxy'));
		s.tab('plugin', _('Plugin Settings'));

		// common settings
		o = s.taboption('common', form.Flag, 'enabled', _('Enable'), _('Enable xfrpc service.'));
		o.rmempty = false;

		o = s.taboption('common', form.Value, 'server_addr', _('Server address'), 
			'%s <br /> %s'.format(_('Server address specifies the address of the server to connect to.'), 
			_('By default, this value is "0.0.0.0".')));
		o.rmempty = false;
		o.datatype = 'or(host, ipaddr)';
		o.optional = false;

		o = s.taboption('common', form.Value, 'server_port', _('Server port'), 
			'%s <br /> %s'.format(_('Server port specifies the port to connect to the server on.'),
			_('By default, this value is 7000.')));
		o.rmempty = false;
		o.datatype = 'port';
		o.optional = false;

		o = s.taboption('common', form.Value, 'token', _('Token'),
			'%s <br /> %s'.format(_('Token specifies the authorization token used to create keys to be \
			sent to the server. The server must have a matching token for authorization to succeed.'), 
			_('By default, this value is "".')));
		o.rmempty = false;
		o.password = true;
		o.optional = false;

		o = s.taboption('common', form.ListValue, 'loglevel', _('Log level'),
			'%s <br /> %s'.format(_('LogLevel specifies the minimum log level. Valid values are "Debug", "Info", \
			"Notice", "Warning", "Error", "Critical", "Alert" and "Emergency".'),
			_('By default, this value is "Info".')));
		o.value(7, _('Debug'));
		o.value(6, _('Info'));
		o.value(5, _('Notice'));
		o.value(4, _('Warning'));
		o.value(3, _('Error'));
		o.value(2, _('Critical'));
		o.value(1, _('Alert'));
		o.value(0, _('Emergency'));
		o.defaulValue = 0;
		o.optional = false;

		// TCP proxy settings
		o = s.taboption('tcp', form.SectionValue, '_tcp', form.GridSection, 'tcp');
		ss = o.subsection;
		ss.addremove = true;
		ss.nodescriptions = true;
		o = ss.option(form.Value, 'local_ip', _('Local IP'),
			_('Local IP specifies the IP address to proxy to.'));
		o.datatype = 'ip4addr';
		o.rmempty = false;
		o.mandatory = true;
		o.optional = false;
		o = ss.option(form.Value, 'local_port', _('Local port'),
			_('Local port specifies the port to proxy to.'));
		o.datatype = 'port';
		o.rmempty = false;
		o.optional = false;
		o = ss.option(form.Value, 'remote_port', _('Remote port'),
			_('Remote port specifies server-side port to proxy to.'));
		o.datatype = 'port';
		o.rmempty = false;
		o.optional = false;

		// HTTP&HTTPS proxy settings
		for (var i = 0; i < web_proxy.length; i++) {
			var proxy = web_proxy[i];
			o = s.taboption(proxy, form.SectionValue, '_'+proxy, form.GridSection, proxy);
			ss = o.subsection;
			ss.addremove = true;
			ss.nodescriptions = true;
			o = ss.option(form.Value, 'local_ip', _('Local IP'),
				_('Local IP specifies the IP address to proxy to.'));
			o.datatype = 'ip4addr';
			o.rmempty = false;
			o.optional = false;
			o = ss.option(form.Value, 'local_port', _('Local port'),
				_('Local port specifies the port to proxy to.'));
			o.datatype = 'port';
			o.optional = false;
			o.rmempty = false;
			o = ss.option(form.Flag, 'is_subdomain', _('Enable Subdomain'),
				_('Enable subdomain for http or https proxy'));
			o.rmempty = false;
			o.modalonly = true;
			o.optional = true;
			o = ss.option(form.Value, 'custom_domains', _('Custom Domains'),
				_('Custom domains for http or https proxy'));
			o.datatype = 'host';
			o.optional = false;
			o.depends('is_subdomain', '0');
			o = ss.option(form.Value, 'subdomain', _('Subdomain'),
				_('Specifies the subdomain for http or https proxy, only works when server support subdomain.'));
			o.datatype = 'string';
			o.optional = false;
			o.depends('is_subdomain', '1');
		}

		// SOCKS5 proxy settings
		o = s.taboption('socks5', form.SectionValue, '_socks5', form.GridSection, 'socks5');
		ss = o.subsection;
		ss.addremove = true;
		ss.nodescriptions = true;
		o = ss.option(form.Value, 'remote_port', _('Remote port'),
			_('Remote port specifies server-side port to proxy to.'));
		o.optional = false;
		o.rmempty = false;
		o.datatype = 'port';
		
		// plugin settings
		o = s.taboption('plugin', form.SectionValue, '_plugin', form.GridSection, 'plugin');
		ss = o.subsection;
		ss.addremove = true;
		ss.nodescriptions = true;
		o = ss.option(form.ListValue, 'plugin_name', _('Plugin Name'),
			_('Specifies the name of remote xfrpc plugin.'));
		o.value('instaloader', _('instagram video downloader'));
		o.value('youtubedl', _('youtube video downloader'));
		o.optional = false;
		o = ss.option(form.ListValue, 'plugin_action', _('Plugin Action'),
			_('Specifies the action sending to remote xfrpc plugin.'));
		o.value('download', _('start download video'));
		o.value('stop', _('stop remote plugin service'));
		o.optional = false;
		o = ss.option(form.Value, 'plugin_param', _('Plugin Param'),
			_('Specifies the parameter sending to remote xfrpc plugin.'));
		o.rmempty = false;
		o.optional = true;
		o.depends('plugin_action', 'download');
		o = ss.option(form.Value, 'remote_port', _('Remote Port'),
			_('Remote port of plugin specifies the remote port of remote xfrpc plugin.'));
		o.datatype = 'port';
		o.rmempty = false;
		o.optional = false;
		
		ss.renderRowActions = function(section_id) {
			var tdEl = this.super('renderRowActions', [ section_id, _('Edit') ]);

			dom.content(tdEl.lastChild, [
				E('button', {
					'class': 'btn cbi-button cbi-button-next',
					'click': executePluginAction.bind(this, section_id),
					'title': _('Execute the plugin action'),
				}, _('Execute')),
				tdEl.lastChild.firstChild,
				tdEl.lastChild.lastChild
			]);

			return tdEl;
		};

		// add button
		return m.render();
	}
});
