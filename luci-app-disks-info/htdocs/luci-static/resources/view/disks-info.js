'use strict';
'require fs';
'require ui';
'require view';

document.head.append(E('style', {'type': 'text/css'},
`
:root {
	--app-disks-info-dark-font-color: #2e2e2e;
	--app-disks-info-light-font-color: #fff;
	--app-disks-info-ok-color: #2ea256;
	--app-disks-info-warn-color: #fff7e2;
	--app-disks-info-err-color: #ff4e54;
}
:root[data-darkmode="true"] {
	--app-disks-info-dark-font-color: #fff;
	--app-disks-info-light-font-color: #fff;
	--app-disks-info-ok-color: #2ea256;
	--app-disks-info-warn-color: #8d7000;
	--app-disks-info-err-color: #a93734;
}
.disks-info-label-status {
	display: inline;
	margin: 0 4px !important;
	padding: 1px 4px;
	-webkit-border-radius: 3px;
	-moz-border-radius: 3px;
	border-radius: 3px;
	text-transform: uppercase;
	font-weight: bold;
	line-height: 1.6em;
}
.disks-info-ok {
	background-color: var(--app-disks-info-ok-color) !important;
	color: var(--app-disks-info-light-font-color) !important;
}
.disks-info-warn {
	background-color: var(--app-disks-info-warn-color) !important;
	color: var(--app-disks-info-dark-font-color) !important;
}
.disks-info-warn .td {
	color: var(--app-disks-info-dark-font-color) !important;
}
.disks-info-warn td {
	color: var(--app-disks-info-dark-font-color) !important;
}
.disks-info-err {
	background-color: var(--app-disks-info-err-color) !important;
	color: var(--app-disks-info-light-font-color) !important;
}
.disks-info-err .td {
	color: var(--app-disks-info-light-font-color) !important;
}
.disks-info-err td {
	color: var(--app-disks-info-light-font-color) !important;
}
`));

return view.extend({
	fsSpaceWarning     : 90,

	ssdEnduranceWarning: 95,

	smartCriticalAttrs : [ 5, 11, 183, 184, 187, 196, 197, 198, 200, 202, 220 ],

	smartTempAttrs     : [ 190, 194 ],

	deviceRegExp       : new RegExp('^((h|s)d[a-z]|nvme[0-9]+n[0-9]+)$'),

	getDeviceData(device) {
		return Promise.all([
			device,
			L.resolveDefault(fs.exec('/usr/sbin/fdisk', [ '-l', device ]), null),
			L.resolveDefault(fs.exec_direct(
				'/usr/sbin/smartctl',
				[ '-iAHl', 'scttemp', '-l', 'error', '-l', 'devstat', '--json=c', device ],
				'json'), null),
		]);
	},

	setSctTempLogInterval(device) {
		let deviceNormalized = device.replace(/\//g, '-');
		let num   = document.getElementById('logging_interval_value' + deviceNormalized).value;
		let pSave = document.getElementById('logging_interval_type' + deviceNormalized).checked;

		if(/^[0-9]{1,2}$/.test(num) && Number(num) > 0) {
			num = String(Number(num));
		} else {
			return;
		};

		return fs.exec('/usr/sbin/smartctl',
			[ '-l', 'scttempint,' + (pSave ? num + ',p' : num), device ]
		).then(res => {
			window.location.reload();
		}).catch(e => ui.addNotification(null, E('p', {}, e.message)));
	},

	async createDiskTable(text) {
		let [ diskInfo, partitions ] = text.trim().split('\n\n').map(e => e.trim().split('\n'));
		diskInfo = diskInfo.map(e => e.split(':'));

		let diskInfoTable = E('table', { 'class': 'table' });
		for(let [k, v] of diskInfo) {
			diskInfoTable.append(
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left', 'style':'min-width:33%' }, _(k) + ':'),
					E('td', { 'class': 'td left' }, v.trim()),
				])
			);
		};

		let partitionsTablePlaceholder = E('tr', { 'class': 'tr placeholder' },
			E('td', { 'class': 'td' },
				E('em', {}, _('No partitions available'))
			)
		);
		let dfTablePlaceholder = E('tr', { 'class': 'tr placeholder' },
			E('td', { 'class': 'td' },
				E('em', {}, _('No mounted filesystems'))
			)
		);
		let partitionsTableTitles = [
			_('Device'),
			_('Boot'),
			_('Start'),
			_('End'),
			_('Sectors'),
			_('Size'),
			_('Id'),
			_('Type'),
		];
		let partitionsTable = E('table', { 'class': 'table' },
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th left' }, partitionsTableTitles[0]),
				E('th', { 'class': 'th left' }, partitionsTableTitles[1]),
				E('th', { 'class': 'th left' }, partitionsTableTitles[2]),
				E('th', { 'class': 'th left' }, partitionsTableTitles[3]),
				E('th', { 'class': 'th left' }, partitionsTableTitles[4]),
				E('th', { 'class': 'th left' }, partitionsTableTitles[5]),
				E('th', { 'class': 'th left' }, partitionsTableTitles[6]),
				E('th', { 'class': 'th left' }, partitionsTableTitles[7]),
			])
		);
		let dfTableTitles = [
			_('Filesystem'),
			_('Type'),
			_('Size'),
			_('Used'),
			_('Available'),
			_('Use') + ' %',
			_('Mounted on'),
		];
		let dfTable = E('table', { 'class': 'table' },
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th left' }, dfTableTitles[0]),
				E('th', { 'class': 'th left' }, dfTableTitles[1]),
				E('th', { 'class': 'th left' }, dfTableTitles[2]),
				E('th', { 'class': 'th left' }, dfTableTitles[3]),
				E('th', { 'class': 'th left' }, dfTableTitles[4]),
				E('th', { 'class': 'th center' }, dfTableTitles[5]),
				E('th', { 'class': 'th left' }, dfTableTitles[6]),
			])
		);

		if(partitions) {
			partitions = partitions.map(e => e.split(/\s+/));

			for(let i = 1; i < partitions.length; i++) {
				let device, boot, start, end, sectors, size, id, type;
				if(partitions[i][1] === '*') {
					[ device, boot, start, end, sectors, size, id, ...type ] = partitions[i];
				} else {
					[ device, start, end, sectors, size, id, ...type ] = partitions[i];
				};

				let tr = E('tr', { 'class': 'tr' });
				[ device, boot || '&#160;', start, end, sectors, size, id, type.join(' ') ].forEach(
					(elem, index, array) => {
						tr.append(
							E('td', {
								'class'     : 'td left',
								'data-title': partitionsTableTitles[index],
							}, elem)
						);
					}
				);

				partitionsTable.append(tr);
			};

			if(partitionsTable.children.length <= 1) {
				partitionsTable.append(partitionsTablePlaceholder);
			} else {

				for(let partition of partitions.slice(1)) {
					let tr = E('tr', { 'class': 'tr' });
					await fs.exec('/bin/df', [ '-Th', partition[0] ]).then(stat => {
						if(stat.code !== 0) return;
						let fields = stat.stdout.trim().split('\n')[1].split(/\s+/);

						for(let i = 0; i < fields.length; i++) {
							tr.append(
								E('td', {
										'class': (i === 5 && parseInt(fields[i]) >= this.fsSpaceWarning) ?
											'td left disks-info-warn' : 'td left',
										'data-title': dfTableTitles[i],
									},
									(i === 5) ? E('div', {
											'class': 'cbi-progressbar',
											'title': fields[i],
											'style': 'min-width:8em !important',
										},
										E('div', { 'style': 'width:' + fields[i] })
									) :
									fields[i]
								)
							);
						};
						dfTable.append(tr);

					});
				};

				if(dfTable.children.length <= 1) {
					dfTable.append(dfTablePlaceholder);
				};
			};
		} else {
			partitionsTable.append(partitionsTablePlaceholder);
			dfTable.append(dfTablePlaceholder);
		};

		return E([
			E('div', { 'class': 'cbi-value' }, diskInfoTable),
			E('div', { 'class': 'cbi-value' }, [
				E('h3', {}, _('Partitions') + ':'),
				partitionsTable,
			]),
			E('div', { 'class': 'cbi-value' }, [
				E('h3', {}, _('Filesystems') + ':'),
				dfTable,
			]),
		]);
	},

	createSmartTable(smartObject) {
		let smartStatusLabel = (smartObject.smart_status.passed) ?
			E('span', { 'class': 'disks-info-label-status disks-info-ok' }, _('passed')) :
			E('span', { 'class': 'disks-info-label-status disks-info-err' }, _('failed'));

		let smartStatus = E('h5', { 'style': 'width:100% !important; text-align:center !important' }, [
			_('SMART overall-health self-assessment test result:'),
			smartStatusLabel,
		]);

		let smartAttrsTable = E('table', { 'class': 'table' },
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th right' }, _('Id')),
				E('th', { 'class': 'th left' }, _('Attribute name')),
				E('th', { 'class': 'th left' }, _('RAW')),
				E('th', { 'class': 'th left' }, _('VALUE')),
				E('th', { 'class': 'th left' }, _('WORST')),
				E('th', { 'class': 'th left' }, _('THRESH')),
				E('th', { 'class': 'th left' }, _('WHEN FAILED')),
			])
		);

		for(let attr of smartObject.ata_smart_attributes.table) {
			let tempValue;
			let lineStyle = (attr.value <= attr.thresh) ? 'tr disks-info-err' :
				(this.smartCriticalAttrs.includes(attr.id) && attr.raw.value > 0) ? 'tr disks-info-warn' :
					(this.smartTempAttrs.includes(attr.id) && +(attr.raw.string.split(' ')[0]) >= this.diskTempWarning) ?
					'tr disks-info-warn' : 'tr';

			smartAttrsTable.append(
				E('tr', {
					'class': lineStyle,
				}, [
					E('td', { 'class': 'td right', 'data-title': _('Id') },
						E('span', {
							'style': 'cursor:help; border-bottom:1px dotted',
							'data-tooltip': 'hex: %02X'.format(attr.id)
						}, attr.id)
					),
					E('td', { 'class': 'td left', 'data-title': _('Attribute name') },
						attr.name.replace(/_/g, ' ')),
					E('td', { 'class': 'td left', 'data-title': _('RAW') },
						E('span', {
							'style': 'cursor:help; border-bottom:1px dotted; font-weight:bold',
							'data-tooltip': 'hex: %012X'.format(attr.raw.value)
						}, attr.raw.string)
					),
					E('td', { 'class': 'td left', 'data-title': _('VALUE') },
						'%03d'.format(attr.value)),
					E('td', { 'class': 'td left', 'data-title': _('WORST') },
						'%03d'.format(attr.worst)),
					E('td', { 'class': 'td left', 'data-title': _('THRESH') },
						'%03d'.format(attr.thresh)),
					E('td', { 'class': 'td left', 'data-title': _('WHEN FAILED') },
						attr.when_failed || '-'),
				])
			);
		};

		return E('div', { 'class': 'cbi-value' }, [
			E('h3', {}, _('S.M.A.R.T.') + ':'),
			smartStatus,
			smartAttrsTable,
		]);
	},

	createErrorLog(table) {
		let errorLogTable = E('table', { 'class': 'table' },
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th left', 'style':'min-width:16%' }, _('Error number')),
				E('th', { 'class': 'th left', 'style':'min-width:17%' }, _('Lifetime hours')),
				E('th', { 'class': 'th left' }, _('Description')),
			])
		);
		for(let errObj of table) {
			errorLogTable.append(
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, errObj.error_number),
					E('td', { 'class': 'td left' }, errObj.lifetime_hours),
					E('td', { 'class': 'td left' }, errObj.error_description),
				])
			);
		};
		return E('div', { 'class': 'cbi-value' }, [
			E('h3', {}, _('S.M.A.R.T. error log') + ':'),
			E('div', { 'style': 'width:100%; max-height:20em; overflow:auto' },
				errorLogTable
			),
		]);
	},

	createTempTable(smartObject) {
		return E('div', { 'class': 'cbi-value' }, [
			E('h3', {}, _('Temperature') + ':'),
			E('table', { 'class': 'table' }, [
				E('tr', {
					'class': (smartObject.temperature.current >= smartObject.temperature.op_limit_max) ?
						'tr disks-info-err' : (smartObject.temperature.current >= this.diskTempWarning) ?
							'tr disks-info-warn' : 'tr',
				}, [
					E('td', { 'class': 'td left', 'style':'min-width:33%' }, _('Current') + ':'),
					E('td', { 'class': 'td left' }, ('current' in smartObject.temperature) ?
						smartObject.temperature.current  + ' °C' : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Lifetime min') + ':'),
					E('td', { 'class': 'td left' }, ('lifetime_min' in smartObject.temperature) ?
						smartObject.temperature.lifetime_min  + ' °C' : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Lifetime max') + ':'),
					E('td', { 'class': 'td left' }, ('lifetime_max' in smartObject.temperature) ?
						smartObject.temperature.lifetime_max  + ' °C' : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Recommended min') + ':'),
					E('td', { 'class': 'td left' }, ('op_limit_min' in smartObject.temperature) ?
						smartObject.temperature.op_limit_min  + ' °C' : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Recommended max') + ':'),
					E('td', { 'class': 'td left' }, ('op_limit_max' in smartObject.temperature) ?
						smartObject.temperature.op_limit_max  + ' °C' : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Limit min') + ':'),
					E('td', { 'class': 'td left' }, ('limit_min' in smartObject.temperature) ?
						smartObject.temperature.limit_min  + ' °C' : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Limit max') + ':'),
					E('td', { 'class': 'td left' }, ('limit_max' in smartObject.temperature) ?
						smartObject.temperature.limit_max  + ' °C' : null),
				]),
			])
		]);
	},

	createSctTempArea(smartObject) {
		let device      = smartObject.device.name;
		let deviceTime  = smartObject.local_time.time_t;
		let intervalMin = smartObject.ata_sct_temperature_history.logging_interval_minutes;
		let intervalSec = intervalMin * 60;
		let dataSize    = smartObject.ata_sct_temperature_history.size;
		let tempData    = smartObject.ata_sct_temperature_history.table;
		let dataUnits   = [];
		let tempMin     = tempData.reduce(
			(min, current) => (current < min && current !== null) ? current : min,
			Infinity);
		let tempMax     = tempData.reduce(
			(max, current) => (current > max && current !== null) ? current : max,
			-Infinity);
		let tempDiff    = tempMax - tempMin;

		let i = dataSize - 1;
		while(i >= 0) {
			if(deviceTime % intervalSec === 0) {
				dataUnits.push([i, tempData[i], new Date(deviceTime * 1000)]);
				i--;
			};
			deviceTime--;
		};
		dataUnits.reverse();

		/* GRAPH */

		let svgWidth         = 900;
		let svgHeight        = 300;
		let tempValueMul     = (tempDiff >= 60) ? 3 : Math.round(svgHeight / (tempDiff + 20));	// 1°C = "tempValueMul"px
		let tempMinimalValue = (tempMin > 10) ? tempMin - 10 : 0;
		let tempAxisStep     = (tempDiff >= 60) ? 6 : (tempDiff >= 30) ? 4 : 2;
		let timeAxisStep     = svgWidth / dataSize;
		let timeAxisInterval = Math.ceil(dataSize / 32);

		let svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
			svg.setAttribute('width', '100%');
			svg.setAttribute('height', '100%');
			svg.setAttribute('version', '1.1');
			svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

		// temperature line
		let tempLine   = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
			tempLine.setAttribute('style', 'fill:#ADD3E6; fill-opacity:1; stroke:#006282; stroke-width:1');
		let tempPoints = [[0, svgHeight]];

		for(let i = 0; i < dataSize; i++) {
			tempPoints.push([
				i * timeAxisStep,
				(dataUnits[i][1] != null) ?
					(svgHeight - (dataUnits[i][1] - tempMinimalValue) * tempValueMul) :
						svgHeight * 2
			]);
		};
		tempPoints.push([tempPoints[tempPoints.length - 1][0], svgHeight]);
		tempLine.setAttribute('points', tempPoints.map(e => e.join(',')).join(' '));
		svg.appendChild(tempLine);

		// temperature warning
		let lineW = document.createElementNS('http://www.w3.org/2000/svg', 'line');
			lineW.setAttribute('x1', 0);
			lineW.setAttribute('y1', svgHeight - (this.diskTempWarning - tempMinimalValue) * tempValueMul);
			lineW.setAttribute('x2', '100%');
			lineW.setAttribute('y2', svgHeight - (this.diskTempWarning - tempMinimalValue) * tempValueMul);
			lineW.setAttribute('style', 'stroke:orange; stroke-width:0.8');
		svg.appendChild(lineW);

		// temperature critical
		let lineC = document.createElementNS('http://www.w3.org/2000/svg', 'line');
			lineC.setAttribute('x1', 0);
			lineC.setAttribute('y1', svgHeight - (this.diskTempCritical - tempMinimalValue) * tempValueMul);
			lineC.setAttribute('x2', '100%');
			lineC.setAttribute('y2', svgHeight - (this.diskTempCritical - tempMinimalValue) * tempValueMul);
			lineC.setAttribute('style', 'stroke:red; stroke-width:0.7');
		svg.appendChild(lineC);

		// time labels
		let j = 0;
		for(let i = 0; i < svgWidth; i += timeAxisStep * timeAxisInterval) {
			let line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
				line.setAttribute('x1', i);
				line.setAttribute('y1', 0);
				line.setAttribute('x2', i);
				line.setAttribute('y2', '100%');
				line.setAttribute('style', 'stroke:rgba(122,122,122,0.2); stroke-width:1');
			svg.appendChild(line);
			let text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
				text.setAttribute('x', i + 6);
				text.setAttribute('y', 0);
				text.setAttribute('style', 'fill:rgba(122,122,122,0.5); font-family:monospace; font-size:12px; font-weight:bold; writing-mode:vertical-rl');
				if(i >= 2 * timeAxisStep * timeAxisInterval) {
					text.appendChild(document.createTextNode('%02d.%02d %02d:%02d'.format(
						dataUnits[j][2].getDate(),
						dataUnits[j][2].getMonth() + 1,
						dataUnits[j][2].getHours(),
						dataUnits[j][2].getMinutes()
					)));
				};
				j += timeAxisInterval;
			svg.appendChild(text);
			if(j >= dataSize) {
				break;
			};
		};

		// temperature labels
		let c = 0;
		for(let i = svgHeight; i > 0; i -= tempValueMul * tempAxisStep) {
			let line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
				line.setAttribute('x1', 0);
				line.setAttribute('y1', i);
				line.setAttribute('x2', '100%');
				line.setAttribute('y2', i);
				line.setAttribute('style', 'stroke:rgba(122,122,122,0.2); stroke-width:1');
			svg.appendChild(line);
			let text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
				text.setAttribute('x', 0);
				text.setAttribute('y', i - 3);
				text.setAttribute('style', 'fill:#eee; font-family:monospace; font-size:14px; text-shadow:1px 1px 1px #000');
				if(c % 2 === 0) {
					text.appendChild(document.createTextNode(((svgHeight - i) / tempValueMul) + tempMinimalValue + ' °C'));
				};
			svg.appendChild(text);
			c++;
		};

		// temperature min/max, log interval
		let text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
			text.setAttribute('x', svgWidth / 3);
			text.setAttribute('y', svgHeight - 10);
			text.setAttribute('style', 'fill:#eee; font-family:monospace; font-size:12px; text-shadow:1px 1px 1px #000');
			text.appendChild(document.createTextNode(`Interval:${intervalMin}m Tmin:${tempMin}°C Tmax:${tempMax}°C`));
		svg.appendChild(text);

		/* TABLE */

		dataUnits = dataUnits.filter((e, i, a) => {
			return e[1] != ((a[i - 1] !== undefined) && a[i - 1][1]);
		});

		let sctTempTable = E('table', { 'class': 'table' },
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th left', 'style':'min-width:33%' }, _('Index')),
				E('th', { 'class': 'th left', 'style':'min-width:33%' }, _('Estimated time')),
				E('th', { 'class': 'th left' }, _('Temperature') + ' °C'),
			])
		);

		for(let [num, temp, date] of dataUnits) {
			if(temp === null) continue;
			sctTempTable.append(
				E('tr', {
					'class': (temp >= this.diskTempCritical) ? 'tr disks-info-err' :
						(temp >= this.diskTempWarning) ? 'tr disks-info-warn' : 'tr',
				}, [
					E('td', { 'class': 'td left', 'data-title': _('Index') },
						num),
					E('td', { 'class': 'td left', 'data-title': _('Estimated time') },
						'%d-%02d-%02d %02d:%02d'.format(
							date.getFullYear(),
							date.getMonth() + 1,
							date.getDate(),
							date.getHours(),
							date.getMinutes()
					)),
					E('td', { 'class': 'td left', 'data-title': _('Temperature') + ' °C' },
						temp),
				])
			);
		};

		let deviceNormalized     = device.replace(/\//g, '-');
		let loggingIntervalValue = E('input', {
			'id'          : 'logging_interval_value' + deviceNormalized,
			'type'        : 'text',
			'class'       : 'cbi-input-text',
			'style'       : 'width:4em !important; min-width:4em !important',
			'maxlength'   : 4,
			'value'       : 1,
			'placeholder' : '1-1440',
		});
		ui.addValidator(loggingIntervalValue, 'range(1,1440)', false);

		return E([
			E('div', { 'class': 'cbi-value' }, [
				E('h3', {},
					`${_('SCT temperature history')} (${_('interval')}: ${intervalMin} ${_('min')}.):`),
				E('div', { 'style': 'width:100%; min-height:' + (svgHeight + 20) + 'px; overflow:auto; margin-top:0.2em' },
					E('div', {
						'style': 'width:' + svgWidth + 'px; height:' + svgHeight + 'px; margin:auto',
					}, svg)
				),
				E('div', { 'style': 'width:100%; max-height:20em; overflow:auto; margin-top:0.2em' },
					sctTempTable
				),
			]),

			E('div', { 'class': 'cbi-value' }, [
				E('label', { 'class': 'cbi-value-title', 'for': 'logging_interval_value' + deviceNormalized },
					_('Set logging interval') + ' (' + _('min') + ')'),
				E('div', { 'class': 'cbi-value-field' }, loggingIntervalValue),
			]),
			E('div', { 'class': 'cbi-value' }, [
				E('label', { 'class': 'cbi-value-title', 'for': 'logging_interval_type' + deviceNormalized },
					_('Preserve across power cycles')),
				E('div', { 'class': 'cbi-value-field' },
					E('div', { 'class': 'cbi-checkbox' }, [
						E('input', {
							'type': 'checkbox',
							'id'  : 'logging_interval_type' + deviceNormalized,
						}),
						E('label', {})
					])
				),
			]),
			E('div', { 'class': 'cbi-value' }, [
				E('label', { 'class': 'cbi-value-title', 'for': 'apply_interval_value' + deviceNormalized },
					_('Write to device memory')
				),
				E('div', { 'class': 'cbi-value-field' }, [
					E('div', {}, E('button', {
						'class': 'btn cbi-button-apply important',
						'click': ui.createHandlerFn(this, this.setSctTempLogInterval, device),
					}, _('Apply'))),
					E('input', {
						'id'  : 'apply_interval_value' + deviceNormalized,
						'type': 'hidden',
					}),
				]),
				E('hr'),
			]),

		]);
	},

	createDeviceStatistics(statObject) {
		let statsArea = E('div', { 'class': 'cbi-value' },
			E('h3', {}, _('Device statistics') + ':')
		);
		for(let page of statObject.pages) {
			if(!page || !Array.isArray(page.table) || page.table.length === 0) continue;
			let pageTableTitle = E('h5', { 'style': 'width:100% !important; text-align:left !important' }, _(page.name));
			let pageTable = E('table', { 'class': 'table' });
			for(let entry of page.table) {
				pageTable.append(
					E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'style':'min-width:33%' }, _(entry.name) + ':'),
						(page.number === 7 && entry.offset === 8) ?
							E('td', {
									'class': (entry.value >= this.ssdEnduranceWarning) ?
										'td left disks-info-warn' : 'td left',
								},
								E('div', {
									'class': 'cbi-progressbar',
									'title': entry.value + '%',
									'data-tooltip': _('May not be supported by some devices...'),
								},
									E('div', { 'style': 'width:' + entry.value + '%' })
								)
							)
						:
							E('td', { 'class': 'td left' }, entry.value),
					])
				);
			};
			statsArea.append(pageTableTitle);
			statsArea.append(pageTable);
		};
		return statsArea;
	},

	createDeviceTable(smartObject) {
		return E('div', { 'class': 'cbi-value' }, [
			E('h3', {}, _('Device') + ':'),
			E('table', { 'class': 'table' }, [
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left', 'style':'min-width:33%' }, _('Model Family') + ':'),
					E('td', { 'class': 'td left' }, smartObject.model_family),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Device Model') + ':'),
					E('td', { 'class': 'td left' }, smartObject.model_name),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Serial Number') + ':'),
					E('td', { 'class': 'td left' }, smartObject.serial_number),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('LU WWN Device Id') + ':'),
					E('td', { 'class': 'td left' }, ('wwn' in smartObject) ?
						Object.values(smartObject.wwn).map(
							e => e.toString(16)).join(' ') : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Firmware Version') + ':'),
					E('td', { 'class': 'td left' }, smartObject.firmware_version),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('User Capacity') + ':'),
					E('td', { 'class': 'td left' }, ('user_capacity' in smartObject) ?
						`${smartObject.user_capacity.bytes} ${_('bytes')} [${(smartObject.user_capacity.bytes / 1e9).toFixed()} ${_('Gb')}] (${smartObject.user_capacity.blocks} ${_('blocks')})`
						: null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, `${_('Sector Size')} (${_('logical/physical')}):`),
					E('td', { 'class': 'td left' }, ('logical_block_size' in smartObject) ?
						`${smartObject.logical_block_size} ${_('bytes')} / ${smartObject.physical_block_size} ${_('bytes')}`
						: null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Rotation Rate') + ':'),
					E('td', { 'class': 'td left' }, (smartObject.rotation_rate === 0) ?
						_('Solid State Device') : smartObject.rotation_rate),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Form Factor') + ':'),
					E('td', { 'class': 'td left' }, ('form_factor' in smartObject) ?
						smartObject.form_factor.name : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Device is') + ':'),
					E('td', { 'class': 'td left' }, smartObject.in_smartctl_database ?
						_('In smartctl database [for details use: -P show]') :
						_('Not in smartctl database [for details use: -P showall]')),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('ATA Version is') + ':'),
					E('td', { 'class': 'td left' }, ('ata_version' in smartObject) ?
						smartObject.ata_version.string : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('SATA Version is') + ':'),
					E('td', { 'class': 'td left' }, ('sata_version' in smartObject) ?
						smartObject.sata_version.string : null),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, _('Local Time is') + ':'),
					E('td', { 'class': 'td left' }, ('local_time' in smartObject) ?
						smartObject.local_time.asctime : null),
				]),
			])
		]);
	},

	load() {
		return fs.list('/dev').then(stat => {
			let devices = [];
			stat.forEach(e => {
				let fname = e.name;
				if(this.deviceRegExp.test(fname)) {
					devices.push('/dev/' + fname);
				};
			});
			return devices.sort();
		}).catch(e => ui.addNotification(null, E('p', {}, e.message)));
	},

	render(devices) {
		let devicesNode = E('div', { 'class': 'cbi-section fade-in' },
			E('div', { 'class': 'cbi-section-node' },
				E('div', { 'class': 'cbi-value' },
					E('em', {}, _('No devices detected'))
				)
			)
		);

		if(devices && devices.length > 0) {
			devicesNode = E('div', { 'class': 'cbi-section fade-in' },
				E('div', { 'class': 'cbi-section-node' },
					E('div', { 'class': 'cbi-value' },
						E('em', { 'class': 'spinning' }, _('Collecting data...'))
					)
				)
			);

			Promise.all(
				devices.map(device => this.getDeviceData(device))
			).then(async data => {
				let devicesTabs = E('div', { 'class': 'cbi-section fade-in' },
					E('div', { 'class': 'cbi-section-node' },
						E('div', { 'class': 'cbi-value' }, [
							E('div', { 'style': 'width:100%; text-align:right !important' },
								E('button', {
									'class': 'btn',
									'click': () => window.location.reload(),
								}, _('Refresh devices'))
							)
						])
					)
				);

				let tabsContainer = E('div', { 'class': 'cbi-section-node cbi-section-node-tabbed' });
				devicesTabs.append(tabsContainer);

				for(let i = 0; i < data.length; i++) {
					let deviceName = data[i][0];
					let fdisk      = (data[i][1] && data[i][1].code === 0) ? data[i][1].stdout : null;
					let smart      = data[i][2];

					let deviceTab  = E('div', {
						'data-tab'      : i,
						'data-tab-title': deviceName,
					});
					tabsContainer.append(deviceTab);

					if(fdisk) {
						await this.createDiskTable(fdisk).then(elem => deviceTab.append(elem));
					};

					if(smart) {
						let smartObject = smart;

						try {
							smartObject = JSON.parse(smart);
						} catch(err) {};

						this.diskTempWarning  = smartObject.temperature && smartObject.temperature.op_limit_max || 60;
						this.diskTempCritical = smartObject.temperature && smartObject.temperature.limit_max || 80;

						if('smart_status' in smartObject && 'ata_smart_attributes' in smartObject &&
								Array.isArray(smartObject.ata_smart_attributes.table) &&
								smartObject.ata_smart_attributes.table.length > 0) {
							deviceTab.append(this.createSmartTable(smartObject));
						};
						if('ata_smart_error_log' in smartObject) {
							if(smartObject.ata_smart_error_log.summary.table) {
								deviceTab.append(this.createErrorLog(smartObject.ata_smart_error_log.summary.table));
							};
						};
						if('temperature' in smartObject) {
							deviceTab.append(this.createTempTable(smartObject));
						};
						if('ata_sct_temperature_history' in smartObject &&
								Array.isArray(smartObject.ata_sct_temperature_history.table) &&
								smartObject.ata_sct_temperature_history.table.length > 0) {
							deviceTab.append(this.createSctTempArea(smartObject));
						};
						if('ata_device_statistics' in smartObject &&
								Array.isArray(smartObject.ata_device_statistics.pages) &&
								smartObject.ata_device_statistics.pages.length > 0) {
							deviceTab.append(this.createDeviceStatistics(smartObject.ata_device_statistics));
						};
						if('device' in smartObject) {
							deviceTab.append(this.createDeviceTable(smartObject));
						};
					};
				};

				ui.tabs.initTabGroup(tabsContainer.children);
				devicesNode.replaceWith(devicesTabs);
			}).catch(e => ui.addNotification(null, E('p', {}, e.message)));
		};

		return E([
			E('h2', { 'class': 'fade-in' }, _('Disk Devices')),
			E('div', { 'class': 'cbi-section-descr fade-in' },
				_("Information about the connected disk devices.")),
			devicesNode,
		]);
	},

	handleSaveApply: null,
	handleSave     : null,
	handleReset    : null,
});
