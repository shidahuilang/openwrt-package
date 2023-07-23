/* Copyright (C) 2023 ImmortalWrt.org */

'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require view';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList('gowebdav'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['gowebdav']['instances']['instance1']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	var renderHTML;
	if (isRunning) {
		renderHTML = spanTemp.format('green', _('GoWebDav'), _('RUNNING'));
	} else {
		renderHTML = spanTemp.format('red', _('GoWebDav'), _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('gowebdav', _('GoWebDav'),
			_('Simple WebDav server written in Go.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function () {
			poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then(function (res) {
					var view = document.getElementById('service_status');
					view.innerHTML = renderStatus(res);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'gowebdav');

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'listen_port', _('Listen port'));
		o.datatype = 'port';
		o.default = '6086';
		o.rmempty = false;

		o = s.option(form.Value, 'mount_dir', _('Mounting directory'));
		o.default = '/mnt';
		o.rmempty = false;

		o = s.option(form.Flag, 'read_only', _('Read-only mode'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Flag, 'public_access', _('Allow access from Internet'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Flag, 'enable_auth', _('Enable authentication'),
			_('Enable WebDav server authentication.'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'username', _('Username'));
		o.rmempty = false;
		o.depends('enable_auth', '1');

		o = s.option(form.Value, 'password', _('Password'));
		o.password = true;
		o.rmempty = false;
		o.depends('enable_auth', '1');

		o = s.option(form.Flag, 'enable_https', _('Enable HTTPS'),
			_('Use HTTPS instead of HTTP.'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'cert_cer', _('Certificate pubkey path'));
		o.rmempty = false;
		o.depends('enable_https', '1');

		o = s.option(form.Value, 'cert_key', _('Certificate privkey path'));
		o.rmempty = false;
		o.depends('enable_https', '1');

		o = s.option(form.Button, '_reg_patch', _('REG patch for Windows'),
			_('Microsoft Windows does not allow WebDav authentication with plain HTTP for security reasons, and the maximum file size is also limited to 50 MiB only. You can import this REG file to patch the limitations.'));
		o.inputtitle = _('download REG patch');
		o.inputstyle = 'reload';
		o.onclick = function() {
			window.open('https://raw.githubusercontent.com/1715173329/gowebdav/master/allow_http.reg');
		}

		return m.render();
	}
});
