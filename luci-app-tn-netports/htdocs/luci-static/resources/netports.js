/*
 * Copyright (c) 2019-2020 Tano Systems LLC. All Rights Reserved.
 * Anton Kikin <a.kikin@tano-systems.com>
 */

'use strict';
'require ui';
'require uci';
'require firewall';

const NetPortsMode = {
	H: 0,
	V: 1
};

const NetPortsVersion = "2.0.3"

const svgModeSwitch = 
	'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512">' +
	'<path d="M629.657 343.598L528.971 444.284c-9.373 9.372-24.568 ' +
	'9.372-33.941 0L394.343 343.598c-9.373-9.373-9.373-24.569 ' +
	'0-33.941l10.823-10.823c9.562-9.562 25.133-9.34 34.419.492L480 ' +
	'342.118V160H292.451a24.005 24.005 0 0 1-16.971-7.029l-16-16C244.361 ' +
	'121.851 255.069 96 276.451 96H520c13.255 0 24 10.745 24 ' +
	'24v222.118l40.416-42.792c9.285-9.831 24.856-10.054 34.419-.492l10.823 ' +
	'10.823c9.372 9.372 9.372 24.569-.001 33.941zm-265.138 15.431A23.999 ' +
	'23.999 0 0 0 347.548 352H160V169.881l40.416 42.792c9.286 9.831 24.856 ' +
	'10.054 34.419.491l10.822-10.822c9.373-9.373 9.373-24.569 ' +
	'0-33.941L144.971 67.716c-9.373-9.373-24.569-9.373-33.941 0L10.343 ' +
	'168.402c-9.373 9.373-9.373 24.569 0 33.941l10.822 10.822c9.562 9.562 ' +
	'25.133 9.34 34.419-.491L96 169.881V392c0 13.255 10.745 24 24 ' +
	'24h243.549c21.382 0 32.09-25.851 16.971-40.971l-16.001-16z"/></svg>';

const svgExpand =
	'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">' +
	'<path d="M143 352.3L7 216.3c-9.4-9.4-9.4-24.6 0-33.9l22.6-22.6c9.4-9.4 ' +
	'24.6-9.4 33.9 0l96.4 96.4 96.4-96.4c9.4-9.4 24.6-9.4 33.9 0l22.6 ' +
	'22.6c9.4 9.4 9.4 24.6 0 33.9l-136 136c-9.2 9.4-24.4 9.4-33.8 0z"/></svg>';

const svgCollapse =
	'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">' +
	'<path d="M177 159.7l136 136c9.4 9.4 9.4 24.6 0 33.9l-22.6 22.6c-9.4 ' +
	'9.4-24.6 9.4-33.9 0L160 255.9l-96.4 96.4c-9.4 9.4-24.6 9.4-33.9 0L7 ' +
	'329.7c-9.4-9.4-9.4-24.6 0-33.9l136-136c9.4-9.5 24.6-9.5 34-.1z"/></svg>';

var NetPorts = L.Class.extend({
	NetPorts: function(inputConfig) {
		var config = {
			targetElement: null,
			tblCellClasses: 'top left',
			mode: NetPortsMode.V,
			modeSwitchButton: false,
			autoSwitchHtoV: true,
			autoSwitchHtoVThreshold: 6,
			hModeFirstColWidth: 20,
			hModeExpanded: false,
		}

		var self = this;

		var fullUpdate = true;
		var targetElement = null;
		var tableElement = null;
		var mode = NetPortsMode.V;
		var currentData = null;

		var fmtNameAndMAC = function(portData) {
			var elements = [ E('strong', {}, portData.name) ];

			if (portData.hwaddr) {
				elements.push(E('br', {}));
				elements.push(fmtMAC(portData));
			}

			return elements;
		}

		var fmtMAC = function(portData) {
			return portData.hwaddr ? portData.hwaddr.toUpperCase() : '\u00a0'; /* &nbsp; */
		}

		var fmtStatus = function(portData) {
			var status  = '';
			var icon    = '';
			var phyup   = 0;
			var adminup = 0;

			phyup = parseInt(portData.carrier);

			if (portData.adminstate === "up")
				adminup = 1;

			if (adminup)
			{
				if (phyup)
					icon = portData.type + '_up.svg';
				else
					icon = portData.type + '_down.svg';
			}
			else
				icon = portData.type + '_disabled.svg';

			var status = E('div', {
				class: 'netports-linkstatus-icon-container netports-linkstatus-icon-container-' +
					((config.mode === NetPortsMode.H) ? 'h' : 'v')
			});

			status.appendChild(E('img', {
				class: "netports-linkstatus-icon",
				src: L.resource('netports/icons/' + icon)
			}));

			var statusText = E('div', { class: "netports-linkstatus-text" });

			if (adminup)
			{
				if (phyup)
				{
					var speed = parseInt(portData.speed);

					if (speed > 0)
						statusText.innerHTML = speed + '\u00a0' + _('Mbit/s');
					else
						statusText.innerHTML = _('Connected', 'Link status');

					if (portData.duplex === "full")
						statusText.innerHTML += ',<br />' + _('full-duplex');
					else if (portData.duplex === "half")
						statusText.innerHTML += ',<br />' + _('half-duplex');
				}
				else
				{
					statusText.appendChild(E('span', { class: "netports-linkstatus-text-disconnected" }, _('Disconnected', 'Link status')));
					statusText.appendChild(E('br', {}));
					statusText.appendChild(document.createTextNode('\u00a0')); /* &nbsp; */
				}
			}
			else
			{
				statusText.appendChild(E('span', { class: "netports-linkstatus-text-disabled" }, _('Disabled', 'Link status')));
				statusText.appendChild(E('br', {}));
				statusText.appendChild(document.createTextNode('\u00a0')); /* &nbsp; */
			}

			return [ status, statusText ];
		}

		var fmtNetIf = function(portData) {
			var v = portData.ifname
			if (portData.ntm && (portData.ntm.netname || portData.ntm.wifiname))
			{
				if (portData.ntm.netname)
				{
					v += ' (<a href="/cgi-bin/luci/admin/network/network">'
						+ portData.ntm.netname.toUpperCase() + '</a>)';
				}

				if (portData.ntm.wifiname)
				{
					v += "<br />";
					v += '[<a href="/cgi-bin/luci/admin/network/wireless">'
						+ portData.ntm.wifiname + '</a>]';
				}
			}
			return v;
		}

		var fmtBridgeIf = function(portData) {
			if (portData.bridge)
			{
				var v = portData.bridge.ifname;

				if (portData.ntm_bridge && portData.ntm_bridge.netname)
					v += ' (<a href="/cgi-bin/luci/admin/network/network">'
						+ portData.ntm_bridge.netname.toUpperCase() + '</a>)';

				v += ',<br />' + _('port&#160;%d').format(portData.bridge.port);

				return v;
			}
			else
				return '&ndash;';
		}

		var fmtFwZones = function(portData) {
			var z = '';
			var ntm = [];
			var out_ifname = false;

			if (portData.ntm && portData.ntm.fwzone)
				ntm.push(portData.ntm);

			if (portData.ntm_bridge && portData.ntm_bridge.fwzone)
				ntm.push(portData.ntm_bridge);

			if (ntm.length == 0)
				return '&ndash;';

			out_ifname = ntm.length > 1;

			ntm.forEach(function(n) {
				var ifname = '';

				z += '<div class="ifacebox netports-ifacebox">';
				z += '<div class="ifacebox-head netports-ifacebox-head" style="background-color: ' + firewall.getColorForName(n.fwzone) + ';">';

				if (out_ifname)
					ifname = n.netname.toUpperCase() + ': ';

				z += n.fwzone
					? '<strong>'
					  + '<a href="/cgi-bin/luci/admin/network/firewall/zones">'
					  + ifname + n.fwzone + '</a></strong>'
					: '<em>' + _('none') + '</em>';

				z += '</div></div>';
			})

			return z;
		}

		var fmtTx = function(portData) {
			if (portData.stats.tx_bytes)
			{
				return [
					_('%1024.2mB').format(portData.stats.tx_bytes),
					E('br', {}),
					'(%d\u00a0%s)'.format(portData.stats.tx_packets, _('pkts.'))
				];
			}
			else
				return '&ndash;';
		}

		var fmtRx = function(portData) {
			if (portData.stats.rx_bytes)
			{
				return [
					_('%1024.2mB').format(portData.stats.rx_bytes),
					E('br', {}),
					'(%d\u00a0%s)'.format(portData.stats.rx_packets, _('pkts.'))
				];
			}
			else
				return '&ndash;';
		}

		var dataTitles = [
			{ title: _('Name and MAC-address'), vModeMinWidth: "130px", fmtFunc: fmtNameAndMAC, hModeDisable: true },
			{ title: _('Link status'), vModeMinWidth: "165px", fmtFunc: fmtStatus },
			{ title: _('Interface'), fmtFunc: fmtNetIf, hModeExtra: true },
			{ title: _('Bridge member'), fmtFunc: fmtBridgeIf, hModeExtra: true },
			{ title: _('Firewall zones'), fmtFunc: fmtFwZones },
			{ title: _('RX'), fmtFunc: fmtRx, hModeExtra: true },
			{ title: _('TX'), fmtFunc: fmtTx, hModeExtra: true },
			{ title: _('MAC-address'), fmtFunc: fmtMAC, vModeDisable: true, hModeExtra: true },
		]


		var clear = function() {
			/* Clear all child elements for target */
			while (targetElement.firstChild) {
				targetElement.removeChild(targetElement.firstChild);
			}
		}

		var clearTbl = function() {
			/* Clear all child elements for table */
			while (tableElement.firstChild) {
				tableElement.removeChild(tableElement.firstChild);
			}
		}

		var btnModeSwitch = null;
		var btnExpand = null;
		var buttons = [];

		var setMode = function(mode) {
			if (config.mode == mode)
				return;

			if ((mode !== NetPortsMode.V) &&
			    (mode !== NetPortsMode.H))
				return;

			config.mode = mode;
			fullUpdate = true;
			updateData(currentData);
			updateButtons();
		}

		var setHModeExpanded = function(expanded) {
			if (config.hModeExpanded == expanded)
				return;

			config.hModeExpanded = expanded;

			var rows = tableElement.querySelectorAll('.tr.netports-extra');

			rows.forEach(function(row) {
				row.style.display =
					(config.hModeExpanded) ? "table-row" : "none";
			});

			updateButtons();
		}

		var createButtons = function() {
			btnExpand =
				E('button', { class: 'cbi-button', title: _('Toggle additional information') }, svgExpand);

			btnExpand.addEventListener('click', function() {
				if (config.hModeExpanded == true)
					setHModeExpanded(false);
				else
					setHModeExpanded(true);
			});

			buttons.push(btnExpand);

			if (config.modeSwitchButton) {
				btnModeSwitch =
					E('button', { class: 'cbi-button', title: _('Toggle view mode') }, svgModeSwitch);

				btnModeSwitch.addEventListener('click', function() {
					if (config.mode == NetPortsMode.V)
						setMode(NetPortsMode.H);
					else
						setMode(NetPortsMode.V);
				});

				buttons.push(btnModeSwitch);
			}
		}

		var updateButtons = function() {
			if (config.mode == NetPortsMode.H) {
				if (config.hModeExpanded)
					btnExpand.innerHTML = svgCollapse;
				else
					btnExpand.innerHTML = svgExpand;
			}

			btnExpand.style.display =
				(config.mode == NetPortsMode.H) ? "" : "none";
		}

		var createBase = function() {
			clear();
			createButtons();
			updateButtons();

			var title = E('div', { class: 'netports-title' }, [
				E('div', { class: 'netports-copyright' },
					E('a', { href: 'https://github.com/tano-systems/luci-app-tn-netports' },
						'luci-app-tn-netports ' + NetPortsVersion)
				),
				E('div', { class: 'netports-buttons' }, buttons)
			]);

			var table = E('table', { class: 'table netports-table' }, [
				E('tr', { class: 'tr table-titles' },
					E('th', { class: 'th top center' }, '...')
				),
				E('tr', { class: 'tr placeholder' },
					E('td', { class: 'td' },
						E('em', { class: 'spinning' }, _('Collecting data...'))
					)
				)
			]);

			var tableWrapper = E('div', { class: 'table-wrapper' }, table);

			targetElement.appendChild(title);
			targetElement.appendChild(tableWrapper);

			tableElement = table;
		}

		var init = function(inputConfig) {
			config.targetElement = inputConfig.target;
			config.mode = inputConfig.mode !== undefined ? Number(inputConfig.mode) : config.mode;
			config.modeSwitchButton = inputConfig.modeSwitchButton !== undefined ?
				inputConfig.modeSwitchButton : config.modeSwitchButton;
			config.hModeExpanded = inputConfig.hModeExpanded !== undefined
				? inputConfig.hModeExpanded : config.hModeExpanded;
			config.hModeFirstColWidth = inputConfig.hModeFirstColWidth !== undefined
				? inputConfig.hModeFirstColWidth : config.hModeFirstColWidth;
			config.autoSwitchHtoV = inputConfig.autoSwitchHtoV !== undefined
				? inputConfig.autoSwitchHtoV : config.autoSwitchHtoV;
			config.autoSwitchHtoVThreshold = inputConfig.autoSwitchHtoVThreshold !== undefined
				? inputConfig.autoSwitchHtoVThreshold : config.autoSwitchHtoVThreshold;

			targetElement = config.targetElement;

			createBase();
		}

		var updateData = function(data) {
			if (!data || !data.data) {
				data = { data: [], count: 0 };
			}

			if ((config.mode == NetPortsMode.H) && config.autoSwitchHtoV) {
				if (data.data.length > config.autoSwitchHtoVThreshold) {
					/* Auto switch to V */
					if (config.mode !== NetPortsMode.V) {
						config.mode = NetPortsMode.V;
						fullUpdate = true;

						if (btnModeSwitch) {
							btnModeSwitch.setAttribute('disabled', true);
							btnModeSwitch.setAttribute('title', _('Too many ports for horizontal display mode'));
						}

						updateButtons();
					}
				}
				else {
					if (btnModeSwitch) {
						btnModeSwitch.removeAttribute('disabled');
						btnModeSwitch.setAttribute('title', _('Toggle view mode'));
					}
				}
			}

			if (fullUpdate || !currentData) {
				clearTbl();
				if (config.mode == NetPortsMode.V) {
					updateTblHeader(data.data);
				}
				fullUpdate = false;
			}

			if (config.mode == NetPortsMode.H) {
				updateTblHeader(data.data);
			}

			updateTbl(data.data);
			currentData = data;
		}

		var updateTblHeader = function(data) {
			if (config.mode == NetPortsMode.V) {
				/* Vertical mode */
				var titles = [];

				dataTitles.forEach(function(t) {
					if (t.vModeDisable)
						return;

					titles.push(E('th', {
						class: 'th ' + config.tblCellClasses,
						style: (t.vModeMinWidth ? 'min-width: ' + t.vModeMinWidth + ';' : '')
					}, t.title))
				});

				tableElement.appendChild(E('tr', { class: 'tr table-titles' }, titles));
			}
			else {
				/* Horizontal mode */
				var row = [];
				var len = data.length;

				if (len == 0) {
					row.push(E('th', { class: 'th top center' }, '...'));
				}
				else {
					/* First column */
					row.push(E('th', {
						class: 'th ' + config.tblCellClasses,
						style: 'width: ' + config.hModeFirstColWidth + '%;'
					}));

					/* Other columns */
					var col_width = (100 - config.hModeFirstColWidth) / len;

					for (let p = 0; p < len; p++) {
						row.push(E('th', {
							class: 'th ' + config.tblCellClasses,
							style: 'width: ' + col_width + '%;'
						}, data[p].name));
					}
				}

				var thead = tableElement.querySelectorAll('.tr.table-titles');
				var trow = E('tr', { class: 'tr table-titles' }, row);

				if (thead.length) {
					if (trow.innerHTML !== thead.innerHTML)
						tableElement.replaceChild(trow, thead[0]);
				}
				else {
					tableElement.appendChild(trow);
				}
			}
		}

		var updateTbl = function(data) {
			if (!Array.isArray(data))
				return;

			var rows = tableElement.querySelectorAll('.tr');
			var n = 0;

			if (config.mode == NetPortsMode.V) {
				data.forEach(function(port) {
					var tcells = []

					dataTitles.forEach(function(t) {
						if (t.vModeDisable)
							return;

						tcells.push(E('td', {
							'class': 'td ' + config.tblCellClasses }, t.fmtFunc(port)));
					});

					var trow = E('tr', { 'class': 'tr' }, tcells);
					trow.classList.add('cbi-rowstyle-%d'.format((n++ % 2) ? 2 : 1));

					if (rows[n]) {
						/*
						 * Update only changed cells.
						 * This avoids flickering for port type icon.
						 */
						var cells_orig = rows[n].querySelectorAll('.td');

						for (let cn = 0; cn < cells_orig.length; cn++) {
							if (cells_orig[cn].innerHTML !== tcells[cn].innerHTML) {
								rows[n].replaceChild(tcells[cn], cells_orig[cn]);
							}
						}
					}
					else
						tableElement.appendChild(trow);
				});
			}
			else {
				if (data.length) {
					dataTitles.forEach(function(t) {
						if (t.hModeDisable)
							return;

						var tcells = []

						tcells.push(E('td', { 'class': 'td ' + config.tblCellClasses }, t.title))
						data.forEach(function(port) {
							tcells.push(E('td', { 'class': 'td ' + config.tblCellClasses }, t.fmtFunc(port)));
						});

						var trow = E('tr', { 'class': 'tr' }, tcells);
						trow.classList.add('cbi-rowstyle-%d'.format((n++ % 2) ? 2 : 1));
						if (t.hModeExtra)
						{
							trow.classList.add('netports-extra');
							trow.style.display =
								(config.hModeExpanded) ? "table-row" : "none";
						}

						if (rows[n]) {
							/*
							 * Update only changed cells.
							 * This avoids flickering for port type icon.
							 */
							var cells_orig = rows[n].querySelectorAll('.td');

							if (cells_orig.length != tcells.length) {
								tableElement.replaceChild(trow, rows[n]);
							}
							else {
								for (let cn = 0; cn < cells_orig.length; cn++) {
									if (cells_orig[cn].innerHTML !== tcells[cn].innerHTML) {
										rows[n].replaceChild(tcells[cn], cells_orig[cn]);
									}
								}
							}
						}
						else
							tableElement.appendChild(trow);
					});
				}
			}

			while (rows[++n])
				tableElement.removeChild(rows[n]);

			if (tableElement.firstElementChild === tableElement.lastElementChild) {
				var trow = tableElement.appendChild(E('tr', { 'class': 'tr placeholder' }));
				var td = trow.appendChild(E('td', { 'class': 'td top center' }, _('No data to display')));
			}
		}

		/* Public API */
		this.init = init;
		this.updateData = updateData;

		/* Init */
		init(inputConfig);
	}
});

return NetPorts;
