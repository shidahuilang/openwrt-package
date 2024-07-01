/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Copyright (C) 2022 ImmortalWrt.org
 */

'use strict';
'require form';
'require fs';
'require poll';
'require rpc';
'require uci';
'require ui';
'require validation';
'require view';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

var callInitAction = rpc.declare({
	object: 'luci',
	method: 'setInitAction',
	params: ['name', 'action'],
	expect: { result:false }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList('v2raya'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['v2raya']['instances']['v2raya']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning, port) {
	var spanTemp = '<span style="color:%s"><strong>%s %s</strong></span>';
	var renderHTML;
	if (isRunning) {
		var button = String.format('&#160;<a class="btn cbi-button" href="%s:%s" target="_blank" rel="noreferrer noopener">%s</a>',
			window.location.origin, port, _('Open Web Interface'));
		renderHTML = spanTemp.format('green', _('v2rayA'), _('RUNNING')) + button;
	} else {
		renderHTML = spanTemp.format('red', _('v2rayA'), _('NOT RUNNING'));
	}

	return renderHTML;
}

function uploadCertificate(type, filename, ev) {
	L.resolveDefault(fs.exec('/bin/mkdir', [ '-p', '/etc/v2raya/' ]));

	return ui.uploadFile('/etc/v2raya/' + filename, ev.target)
	.then(L.bind(function(btn, res) {
		btn.firstChild.data = _('Checking %s...').format(type);

		if (res.size <= 0) {
			ui.addNotification(null, E('p', _('The uploaded %s is empty.').format(type)));
			return fs.remove('/etc/v2raya/' + filename);
		}

		ui.addNotification(null, E('p', _('Your %s was successfully uploaded. Size: %sB.').format(type, res.size)));
	}, this, ev.target))
	.catch(function(e) { ui.addNotification(null, E('p', e.message)) })
	.finally(L.bind(function(btn, input) {
		btn.firstChild.data = _('Upload...');
	}, this, ev.target));
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('v2raya')
		]);
	},

	handleSaveApply: function(ev, mode) {
		return this.handleSave(ev).then(function() {
			classes.ui.changes.apply(mode == '0');
			callInitAction('v2raya', 'disable').then(function() {
				callInitAction('v2raya', 'restart');
			});
		})
	},

	render: function(data) {
		var m, s, o;
		var webport = (uci.get(data[0], 'config', 'address') || '0.0.0.0:2017').split(':').slice(-1)[0];

		m = new form.Map('v2raya', _('v2rayA'),
			_('v2rayA is a V2Ray Linux client supporting global transparent proxy, compatible with SS, SSR, Trojan(trojan-go), PingTunnel protocols.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function () {
			poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then(function (res) {
					var view = document.getElementById('service_status');
					view.innerHTML = renderStatus(res, webport);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'v2raya');

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'address', _('Listening address'));
		o.datatype = 'ipaddrport(1)';
		o.default = '0.0.0.0:2017';
		o.rmempty = false;

		o = s.option(form.Value, 'config', _('Configuration directory'));
		o.datatype = 'path';
		o.default = '/etc/v2raya';
		o.rmempty = false;

		o = s.option(form.ListValue, 'ipv6_support', _('IPv6 support'),
			_('Make sure your IPv6 network works fine before you turn it on.'));
		o.value('auto', _('Auto'));
		o.value('on', _('On'));
		o.value('off', _('Off'));
		o.default = 'auto';
		o.rmempty = false;

		o = s.option(form.ListValue, 'log_level', _('Log level'));
		o.value('trace', _('Trace'));
		o.value('debug', _('Debug'));
		o.value('info', _('Info'));
		o.value('warn', _('Warn'));
		o.value('error', _('Error'));
		o.default = 'info';
		o.rmempty = false;

		o = s.option(form.Value, 'log_file', _('Log file path'));
		o.datatype = 'path';
		o.default = '/var/log/v2raya/v2raya.log';
		o.rmempty = false;
		/* Due to ACL rule, this value must retain default otherwise log page will be broken */
		o.readonly = true;

		o = s.option(form.Value, 'log_max_days', _('Max log retention period'),
			_('Maximum number of days to keep log files.'));
		o.datatype = 'uinteger';
		o.default = '3';
		o.rmempty = false;

		o = s.option(form.Flag, 'log_disable_color', _('Disable log color output'));
		o.default = o.enabled;
		o.rmempty = false;

		o = s.option(form.Flag, 'log_disable_timestamp', _('Disable log timestamp'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'v2ray_bin', _('v2ray binary path'),
			_('Executable v2ray binary path. Auto-detect if put it empty (recommended).'));
		o.datatype = 'path';

		o = s.option(form.Value, 'v2ray_confdir', _('Extra config directory'),
			_('Additional v2ray config directory, files in it will be combined with config generated by v2rayA.'));
		o.datatype = 'path';

		o = s.option(form.Value, 'vless_grpc_inbound_cert_key', _('Certpath for gRPC inbound'),
			_('Specify the certification path instead of automatically generating a self-signed certificate.'));
		o.value('', _('Automatically generate'));
		o.value('/etc/v2raya/grpc_certificate.crt,/etc/v2raya/grpc_private.key');

		o = s.option(form.Button, '_upload_cert', _('Upload certificate'));
		o.inputstyle = 'action';
		o.inputtitle = _('Upload...');
		o.onclick = L.bind(uploadCertificate, this, _('certificate'), 'grpc_certificate.crt');
		o.depends('vless_grpc_inbound_cert_key', '/etc/v2raya/grpc_certificate.crt,/etc/v2raya/grpc_private.key');

		o = s.option(form.Button, '_upload_key', _('Upload privateKey'));
		o.inputstyle = 'action';
		o.inputtitle = _('Upload...');
		o.onclick = L.bind(uploadCertificate, this, _('private key'), 'grpc_private.key');
		o.depends('vless_grpc_inbound_cert_key', '/etc/v2raya/grpc_certificate.crt,/etc/v2raya/grpc_private.key');

		return m.render();
	}
});
