/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 */

'use strict';
'require view';
'require uci';
'require fs';

return view.extend({
	title: _('IP Information'),
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	load: function () {
		return uci.load('ipinfo').then(function() {
			var data = uci.sections('ipinfo');
			var jsonData = {};
			if (data[0].enable === '0') {
				jsonData.uci = {
					enable: data[0].enable
				};
				return jsonData;
			} else {
				return fs.exec('curl', ['-s', '-m', '5', '-o', '/dev/null', 'https://www.google.com']).then(function(result) {
					if (result.code === 0) {
						if (data.length > 0) {
							var item = data[0];
							jsonData.uci = {
								enable: item.enable,
								isp: item.isp,
								loc: item.loc,
								co: item.co
							};
						} else {
							jsonData.uci = null;
						};
						return fs.exec('curl', ['-sL', 'ip.guide']).then(function(result) {
							var data = JSON.parse(result.stdout);
							jsonData.json = data;
							return jsonData;
						});
					} else {
						return jsonData;
					};
				});
			};
		});
	},
	render: function (data) {
		var container;
		var table = E('table', {'class': 'table'});
		if (!data || Object.keys(data).length === 0) {
			var row = E('tr', {'class': 'tr'}, [
				E('td', {'class': 'td'}, _('No internet connection.'))
			]);
			table.appendChild(row);
			return table;
		} else if (data.uci && data.uci.enable === '1') {
			var hasData = false;
			var categories = ['isp', 'loc', 'co'];
			var propertiesToShow = {
				'ip': _('Public IP'),
				'network.autonomous_system.name': _('Provider'),
				'network.autonomous_system.organization': _('Organization'),
				'network.autonomous_system.asn': _('ASN Number'),
				'location.city': _('City'),
				'location.country': _('Country'),
				'location.timezone': _('Timezone'),
				'location.latitude': _('Latitude'),
				'location.longitude': _('Longitude')
			};
			var dataUci = {
				'ip': 'ip',
				'network.autonomous_system.name': 'name',
				'network.autonomous_system.organization': 'organization',
				'network.autonomous_system.asn': 'asn',
				'location.city': 'city',
				'location.country': 'country',
				'location.timezone': 'timezone',
				'location.latitude': 'latitude',
				'location.longitude': 'longitude'
			};
			categories.forEach(function(category) {
				if (data.uci[category]) {
					data.uci[category].forEach(function(key) {
						var propKey = Object.keys(dataUci).find(k => dataUci[k] === key);
						if (propKey) {
							hasData = true;
							var value = propKey.split('.').reduce((o, i) => o ? o[i] : null, data.json);
							var row = E('tr', {'class': 'tr'}, [
								E('td', {'class': 'td left', 'width': '33%'}, propertiesToShow[propKey]),
								E('td', {'class': 'td left'}, value || '-')
							]);
							table.appendChild(row);
						}
					});
				}
			});
			if (!hasData) {
				var row = E('tr', {'class': 'tr'}, [
					E('td', {'class': 'td'}, _('No data available, please check the settings.'))
				]);
				table.appendChild(row);
			}
			return table;
		} else if (data.uci && data.uci.enable !== '1') {
			return container;
		};
	}
});
