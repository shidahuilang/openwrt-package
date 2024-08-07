/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Copyright (C) 2022 ImmortalWrt.org
 */

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
	return L.resolveDefault(callServiceList('ipsec'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['ipsec']['instances']['instance1']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	var renderHTML;
	if (isRunning) {
		renderHTML = spanTemp.format('green', _('IPSec VPN'), _('RUNNING'));
	} else {
		renderHTML = spanTemp.format('red', _('IPSec VPN'), _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('ipsec')
		]);
	},

	render: function(data) {
		var m, s, o;

		m = new form.Map('ipsec', _('IPSec VPN Server'),
			_('IPSec VPN connectivity using the native built-in VPN Client on iOS or Andriod (IKEv1 with PSK and Xauth)'));

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

		s = m.section(form.NamedSection, 'ipsec', 'service');

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'clientip', _('VPN Client IP'),
			_('LAN DHCP reserved started IP addresses with the same subnet mask'));
		o.datatype = 'ip4addr';
		o.rmempty = false;

		o = s.option(form.Value, 'clientdns', _('VPN Client DNS'),
			_('DNS using in VPN tunnel.Set to the router\'s LAN IP is recommended'));
		o.datatype = 'ip4addr';
		o.rmempty = false;

		o = s.option(form.Value, 'account', _('Account'));
		o.rmempty = false;

		o = s.option(form.Value, 'password', _('Password'));
		o.password = true;
		o.rmempty = false;

		o = s.option(form.Value, 'secret', _('Secret Pre-Shared Key'));
		o.password = true;
		o.rmempty = false;

		return m.render();
	}
});
