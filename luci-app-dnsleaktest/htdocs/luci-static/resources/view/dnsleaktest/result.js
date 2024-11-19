/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 */

'use strict';
'require view';
'require fs';
'require ui';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	load: function() {
			return fs.read('/etc/dnsleaktest/result').then(function(data) {
				var line = data.split('\n');
				var header = line[0].split('|').map(function(item) {
					return item.trim();
				}).filter(function(item) {
					return item !== '';
				});
				var data = [];
				for (var i = 1; i < line.length; i++) {
					if (line[i].trim() === '') {
						continue;
					}
					var value = line[i].split('|').map(function(item) {
						return item.trim();
					}).filter(function(item) {
						return item !== '';
					});
					var dataObj = {};
					for (var j = 0; j < header.length; j++) {
						dataObj[header[j]] = value[j];
					}
					data.push(dataObj);
				}
				return data;
			}).catch(function(error) {
				console.error(error);
				return [];
			})
	},
	render: function(value) {
		var header = [
			E('h2', {'class': 'section-title'}, _('DNS Leak Test')),
			E('div', {'class': 'cbi-map-descr'}, _('Perform a DNS Leak Test to check the security of your DNS settings.'))
		];
		var result;
		if (value.length > 0) {
			var rows = value.map(function(data, index) {
				var rowClass = index % 2 === 0 ? 'cbi-rowstyle-1' : 'cbi-rowstyle-2';
				var download = E('button', {
					'class': 'btn cbi-button cbi-button-save',
					'style': 'margin-right: 10px',
					'click': function() {
						var file = `/etc/dnsleaktest/${data.id}`
						return fs.read(file).then(function(value) {
							var write = new Blob([value], { type: 'text/plain' });
							var link = document.createElement('a');
							var name = _('DNS Leak Test by ID');
							link.href = window.URL.createObjectURL(write);
							link.download = `${name} ${data.id}`;
							link.click();
						}).catch(function(error) {
							console.error(error);
						});
					}
				}, _('Download'));
				var remove = E('button', {
					'class': 'btn cbi-button cbi-button-remove',
					'click': function() {
						ui.showModal(_('Remove data'), [
							E('p', _('Are you sure you want to remove this data?')),
							E('div', {'class': 'right'}, [
								E('button', {
									'class': 'btn cbi-button cbi-button-cancel',
									'style': 'margin-right: 10px',
									'click': ui.hideModal
								}, _('Cancel')),
								E('button', {
									'class': 'btn cbi-button cbi-button-remove',
									'click': function() {
										var file = '/etc/dnsleaktest/result';
										var remove = `/etc/dnsleaktest/${data.id}`;
										fs.read(file).then(function(result) {
											var line = result.split('\n');
											line.splice(index + 1, 1);
											var data = line.join('\n');
											fs.write(file, data);
										});
										fs.remove(remove);
										return window.location.reload();
									}
								}, _('Remove'))
							])
						]);
					}
				}, _('Remove'));
				return E('tr', {'class': 'tr ' + rowClass, 'data-index': index}, [
					E('td', {'class': 'td'}, data.date),
					E('td', {'class': 'td'}, data.time),
					E('td', {'class': 'td'}, data.id),
					E('td', {'class': 'td'}, data.ip),
					E('td', {'class': 'td'}, data.country),
					E('td', {'class': 'td'}, data.dns),
					E('td', {'class': 'td'}, data.server),
					E('td', {'class': 'td'}, data.cons),
					E('td', {'class': 'td'}, [
						E('div', {'class': 'td-actions', 'style': 'display: inline-flex'}, [download, remove])
					])
				]);
			});
			result = [
				E('table', {'class': 'table cbi-section-table'}, [
					E('tr', {'class': 'tr table-titles'}, [
						E('th', {'class': 'th'}, _('Date')),
						E('th', {'class': 'th'}, _('Time')),
						E('th', {'class': 'th'}, _('ID')),
						E('th', {'class': 'th'}, _('IP Address')),
						E('th', {'class': 'th'}, _('Country')),
						E('th', {'class': 'th'}, _('DNS Server')),
						E('th', {'class': 'th'}, _('Servers Found')),
						E('th', {'class': 'th'}, _('Conclusion')),
						E('th', {'class': 'th'})
					]),
					E(rows)
				])
			];
		} else {
			result = E('div', {'class': 'section-info center', 'style': 'padding: 1.25rem 0'}, _('No data available.'))
		};
		return E('div', {'class': 'cbi-map'}, [
			E(header),
			E('div', {'class': 'cbi-section'}, [
				E('h3', {'class': 'section-title'}, _('Results')),
				E(result)
			]),
		])
	}
})
