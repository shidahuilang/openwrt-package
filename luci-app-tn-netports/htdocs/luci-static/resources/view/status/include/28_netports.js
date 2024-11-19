/*
 * Copyright (c) 2019, Tano Systems. All Rights Reserved.
 * Anton Kikin <a.kikin@tano-systems.com>
 */

'use strict';
'require rpc';
'require uci';
'require netports';

var callSessionAccess = rpc.declare({
	object: 'session',
	method: 'access',
	params: [ 'scope', 'object', 'function' ],
	expect: { 'access': false }
});

var callNetPortsGetInfo = rpc.declare({
	object: 'netports',
	method: 'getPortsInfo',
	expect: { '': {} }
});

var netports_el = E('div', {});
var netports_object = null;

return L.Class.extend({
	__init__: function() {
		var head = document.getElementsByTagName('head')[0];
		var css = E('link', { 'href': L.resource('netports/netports.css'), 'rel': 'stylesheet' });
		head.appendChild(css);

		uci.load('luci_netports').then(function() {
			var np_default_additional_info =
				parseInt(uci.get('luci_netports', 'global', 'default_additional_info') || 0) == 1;

			var np_default_h_mode =
				parseInt(uci.get('luci_netports', 'global', 'default_h_mode') || 1) == 1;

			var np_hv_mode_switch_button =
				parseInt(uci.get('luci_netports', 'global', 'hv_mode_switch_button') || 1) == 1;

			netports_object = new netports.NetPorts({
				target: netports_el,
				mode: np_default_h_mode ? 0 : 1,
				modeSwitchButton: np_hv_mode_switch_button,
				autoSwitchHtoV: true,
				autoSwitchHtoVThreshold: 6,
				hModeFirstColWidth: 20,
				hModeExpanded: np_default_additional_info,
			});
		});
	},

	title: _('Network Interfaces Ports Status'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callNetPortsGetInfo(), {}),
			callSessionAccess('access-group', 'luci-app-tn-netports', 'read'),
		]);
	},

	render: function(data) {
		var hasReadPermission = data[1];

		if (!hasReadPermission)
			return E([]);

		if (netports_object)
			netports_object.updateData(data[0]);

		return E([ netports_el ]);
	}
});
