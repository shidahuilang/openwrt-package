/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 */

'use strict';
'require view';
'require fs';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
	render: function() {
		var header = [
			E('h2', {'class': 'section-title'}, _('DNS Leak Test')),
			E('div', {'class': 'cbi-map-descr'}, _('Perform a DNS Leak Test to check the security of your DNS settings.'))
		];
		var status = [
			E('label', { 'class': 'cbi-input-label', 'style': 'margin: 8px;'}, _('Status')),
			E('em', { 'id': 'dnsleak-status'}, _('Available'))
		];
		var infoTable = [
			E('h3', {'class': 'section-title'}, _('Information')),
			E('table', {'class': 'table cbi-section-table', 'id': 'info'}, [
				E('tr', {'class': 'tr table-titles'}, [
					E('th', {'class': 'th'}, _('ID')),
					E('th', {'class': 'th'}, _('IP Address')),
					E('th', {'class': 'th'}, _('Country')),
					E('th', {'class': 'th'}, _('DNS Server')),
					E('th', {'class': 'th'}, _('Servers Found')),
					E('th', {'class': 'th'}, _('Conclusion'))
				]),
			])
		];
		var resultsTable = [
			E('h3', {'class': 'section-title'}, _('Results')),
			E('table', {'class': 'table cbi-section-table', 'id': 'results'}, [
				E('tr', {'class': 'tr table-titles'}, [
					E('th', {'class': 'th'}, _('No')),
					E('th', {'class': 'th'}, _('IP Address')),
					E('th', {'class': 'th'}, _('Country')),
					E('th', {'class': 'th'}, _('DNS Server'))
				]),
			])
		];
		var running = false;
		var button = [
			E('button', {
				'class': 'btn cbi-button cbi-button-action',
				'click': function() {
					if (!running) {
						running = true;
						var statusId = document.getElementById('dnsleak-status');
						var api = 'bash.ws';
						statusId.textContent = _('Running');
						return fs.exec('curl', ['-s', '-m', '5', '-o', '/dev/null', `https://${api}`]).then(function (result) {
							if (result.code === 0) {
								return fs.exec('curl', ['-s', `https://${api}/id`]).then(function (result) {
									if (result.code === 0) {
										var id = result.stdout.trim();
										for (var i = 1; i <= 10; i++) {
											fs.exec_direct('ping', ['-c', '1', `${i}.${id}.${api}`]);
										}
										return fs.exec_direct('curl', ['-s', `https://${api}/dnsleak/test/${id}?json`]).then(function (result) {
											var result = JSON.parse(result);
											var typeIP = result[0];
											var dataCon = result[result.length - 1].ip;
											var totalDNS = result.length - 2;
											var rowsInfo = document.getElementById('info');
											var rowsResults = document.getElementById('results');
											var rowsRemove = document.querySelectorAll('#results .tr, #info .tr');
											var fileResults = '/etc/dnsleaktest/result';
											var fileDNS = `/etc/dnsleaktest/${id}`;
											var index = 0;
											var dataDNS = [];
											var date = new Date().toLocaleDateString(undefined, {
												weekday: 'short',
												month: 'short',
												day: 'numeric'
											});
											var time = new Date().toLocaleTimeString(undefined, {
												hour: '2-digit',
												minute: '2-digit'
											});
											var newRow = E('tr', {'class': 'tr cbi-rowstyle-1'}, [
												E('td', {'class': 'td'}, id),
												E('td', {'class': 'td'}, typeIP.ip),
												E('td', {'class': 'td'}, typeIP.country_name),
												E('td', {'class': 'td'}, typeIP.asn),
												E('td', {'class': 'td'}, totalDNS),
												E('td', {'class': 'td'}, dataCon)
											]);
											rowsInfo.appendChild(newRow);
											for (var i = 0; i < result.length; i++) {
												var typeDNS = result[i];
												if (typeDNS.type === 'dns') {
													index++;
													var rowClass = index % 2 === 0 ? 'cbi-rowstyle-2' : 'cbi-rowstyle-1';
													var newRow = E('tr', {'class': 'tr ' + rowClass}, [
														E('td', {'class': 'td'}, index),
														E('td', {'class': 'td'}, typeDNS.ip),
														E('td', {'class': 'td'}, typeDNS.country_name),
														E('td', {'class': 'td'}, typeDNS.asn)
													]);
													rowsResults.appendChild(newRow);
													var data = `${typeDNS.ip} [${typeDNS.country_name}, ${typeDNS.asn}]\n`;
													dataDNS += data;
												}
											};
											running = false;
											statusId.textContent =  _('Finished');
											var dataInfo = `| ${date} | ${time} | ${id} | ${typeIP.ip} | ${typeIP.country_name} | ${typeIP.asn} | ${totalDNS} | ${dataCon} |\n`;
											var dI0 = _('Test ID');
											var dI1 = _('Date and time of test')
											var dI2 = _('IP Address');
											var dI3 = _('Use');
											var dI4 = _('DNS Servers');
											var dI5 = _('Conclusion');
											var dD1 = `${dI0}:\n${id}\n\n` + `${dI1}:\n${date}, ${time}\n\n` + `${dI2}:\n` + `${typeIP.ip} [${typeIP.country_name}, ${typeIP.asn}]\n\n` + `${dI3} ${totalDNS} ${dI4}:\n`;
											var dD2 = `\n${dI5}:\n${dataCon}\n`;
											fs.read(fileResults).then(function(result) {
												var newData = result.trim() + '\n' + dataInfo;
												fs.write(fileResults, newData);
											}).catch(function(error) {
												running = false;
												statusId.textContent = _('Error writing information data to file') + ` ${fileResults}`;
												console.error(error);et
											});
											fs.write(fileDNS, dD1 + dataDNS + dD2).catch(function(error) {
												running = false;
												statusId.textContent = _('Error writing DNS data to file') + ` ${fileDNS}`;
												console.error(error);
											});
											rowsRemove.forEach(function(row) {
												if (!row.classList.contains('table-titles')) {
													row.remove();
												}
											});
										}).catch(function(error) {
											running = false;
											statusId.textContent = _('An error occurred while getting dnsleak test.');
											console.error(error);
										});
									} else {
										running = false;
										statusId.textContent = _('Failed to get ID.');
									}
									console.log("Running: " + running);
								}).catch(function(error) {
									running = false;
									statusId.textContent = _('An error occurred while getting ID.');
									console.error(error);
								})
							} else {
								running = false;
								statusId.textContent = _('No internet connection. Please check your internet connection or try again later.');
							}
						}).catch(function(error) {
							running = false;
							statusId.textContent = _('Please install curl to run internet test.');
							console.error(error);
						});
					}
				}
			}, _('Start'))
		];
		return E('div', {'class': 'cbi-map'}, [
			E(header),
			E('div', {'class': 'cbi-section-actions', 'style': 'margin: 1.25rem 0'}, [
				E(button),
				E(status)
			]),
			E('div', {'class': 'cbi-section'}, infoTable),
			E('div', {'class': 'cbi-section'}, resultsTable)
		])
	}
})
