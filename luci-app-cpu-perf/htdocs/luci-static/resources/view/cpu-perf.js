'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';

const btnStyleEnabled  = 'btn cbi-button-save';
const btnStyleDisabled = 'btn cbi-button-reset';

return view.extend({
	appName   : 'cpu-perf',
	initStatus: null,

	callCpuPerf: rpc.declare({
		object: 'luci.cpu-perf',
		method: 'getCpuPerf',
		expect: { '': {} }
	}),

	callInitStatus: rpc.declare({
		object: 'luci',
		method: 'getInitList',
		params: [ 'name' ],
		expect: { '': {} }
	}),

	callInitAction: rpc.declare({
		object: 'luci',
		method: 'setInitAction',
		params: [ 'name', 'action' ],
		expect: { result: false }
	}),

	getInitStatus() {
		return this.callInitStatus(this.appName).then(res => {
			if(res) {
				return res[this.appName].enabled;
			} else {
				throw _('Command failed');
			}
		}).catch(e => {
			ui.addNotification(null,
				E('p', _('Failed to get %s init status: %s').format(this.appName, e)));
		});
	},

	handleServiceAction(action) {
		return this.callInitAction(this.appName, action).then(success => {
			if(!success) {
				throw _('Command failed');
			};
			return true;
		}).catch(e => {
			ui.addNotification(null,
				E('p', _('Service action failed "%s %s": %s').format(this.appName, action, e)));
		});
	},

	serviceRestart(ev) {
		poll.stop();
		return this.handleServiceAction('restart').then(() => {
			poll.start();
		});
	},

	freqFormat(freq) {
		if(!freq) {
			return '-';
		};
		return (freq >= 1e6) ?
			(freq / 1e6) + ' ' + _('GHz')
		:
			(freq / 1e3) + ' ' + _('MHz');
	},

	updateCpuPerfData() {
		this.callCpuPerf().then((data) => {
			if(data.cpus) {
				for(let i of Object.values(data.cpus)) {
					document.getElementById('cpu' + i.number + 'number').textContent   =
						_('CPU') + ' ' + i.number;
					document.getElementById('cpu' + i.number + 'curFreq').textContent  =
						(i.sCurFreq) ? this.freqFormat(i.sCurFreq) : this.freqFormat(i.curFreq);
					document.getElementById('cpu' + i.number + 'minFreq').textContent  =
						(i.sMinFreq) ? this.freqFormat(i.sMinFreq) : this.freqFormat(i.minFreq)
					document.getElementById('cpu' + i.number + 'maxFreq').textContent  =
						(i.sMaxFreq) ? this.freqFormat(i.sMaxFreq) : this.freqFormat(i.maxFreq);
					document.getElementById('cpu' + i.number + 'governor').textContent =
						i.governor || '-';
				};
			};
			if(data.ondemand) {
				document.getElementById('OdUpThreshold').textContent =
					data.ondemand.upThreshold || '-';
				document.getElementById('OdIgnNiceLoad').textContent =
					(data.ondemand.ignNiceLoad !== undefined) ?
						data.ondemand.ignNiceLoad : '-';
				document.getElementById('OdSmpDownFactor').textContent =
					data.ondemand.smpDownFactor || '-';
			};
			if(data.conservative) {
				document.getElementById('CFreqStep').textContent =
					(data.conservative.freqStep !== undefined) ?
						data.conservative.freqStep : '-';
				document.getElementById('CDownThreshold').textContent =
					data.conservative.downThreshold || '-';
				document.getElementById('CSmpDownFactor').textContent =
					data.conservative.smpDownFactor || '-';
			};
		}).catch(e => {});
	},

	CBIBlockPerf: form.Value.extend({
		__name__ : 'CBI.BlockPerf',

		__init__(map, section, ctx, perfData) {
			this.map      = map;
			this.section  = section;
			this.ctx      = ctx;
			this.perfData = perfData;
			this.optional = true;
			this.rmempty  = true;
		},

		renderWidget(section_id, option_index, cfgvalue) {
			let cpuTableTitles = [
				_('CPU'),
				_('Current frequency'),
				_('Minimum frequency'),
				_('Maximum frequency'),
				_('Scaling governor'),
			];

			let cpuTable = E('table', { 'class': 'table' },
				E('tr', { 'class': 'tr table-titles' }, [
					E('th', { 'class': 'th left' }, cpuTableTitles[0]),
					E('th', { 'class': 'th left' }, cpuTableTitles[1]),
					E('th', { 'class': 'th left' }, cpuTableTitles[2]),
					E('th', { 'class': 'th left' }, cpuTableTitles[3]),
					E('th', { 'class': 'th left' }, cpuTableTitles[4]),
				])
			);

			let ondemandTable, conservativeTable;

			if(this.perfData) {
				if(this.perfData.cpus) {
					for(let i of Object.values(this.perfData.cpus)) {
						cpuTable.append(
							E('tr', { 'class': 'tr' }, [
								E('td', {
									'id': 'cpu' + i.number + 'number',
									'class': 'td left',
									'data-title': cpuTableTitles[0],
								}, _('CPU') + ' ' + i.number),
								E('td', {
									'id': 'cpu' + i.number + 'curFreq',
									'class': 'td left',
									'data-title': cpuTableTitles[1],
								}, (i.sCurFreq) ?
										this.ctx.freqFormat(i.sCurFreq)
									:
										this.ctx.freqFormat(i.curFreq)
								),
								E('td', {
									'id': 'cpu' + i.number + 'minFreq',
									'class': 'td left',
									'data-title': cpuTableTitles[2],
								}, (i.sMinFreq) ?
										this.ctx.freqFormat(i.sMinFreq)
									:
										this.ctx.freqFormat(i.minFreq)
								),
								E('td', {
									'id': 'cpu' + i.number + 'maxFreq',
									'class': 'td left',
									'data-title': cpuTableTitles[3],
								}, (i.sMaxFreq) ?
										this.ctx.freqFormat(i.sMaxFreq)
									:
										this.ctx.freqFormat(i.maxFreq)
								),
								E('td', {
									'id': 'cpu' + i.number + 'governor',
									'class': 'td left',
									'data-title': cpuTableTitles[4],
								}, i.governor || '-'),
							])
						);
					};
				};
				if(this.perfData.ondemand) {
					ondemandTable = E('table', { 'class': 'table' }, [
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left' }, _("up_threshold")),
							E('td', { 'id': 'OdUpThreshold', 'class': 'td left' },
								this.perfData.ondemand.upThreshold || '-'),
						]),
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left' }, _("ignore_nice_load")),
							E('td', { 'id': 'OdIgnNiceLoad', 'class': 'td left' },
								(this.perfData.ondemand.ignNiceLoad !== undefined) ?
									this.perfData.ondemand.ignNiceLoad : '-'),
						]),
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left', 'style':'min-width:33%' }, _("sampling_down_factor")),
							E('td', { 'id': 'OdSmpDownFactor', 'class': 'td left' },
								this.perfData.ondemand.smpDownFactor || '-'),
						]),
					]);
				};
				if(this.perfData.conservative) {
					conservativeTable = E('table', { 'class': 'table' }, [
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left' }, _("freq_step")),
							E('td', { 'id': 'CFreqStep', 'class': 'td left' },
								(this.perfData.conservative.freqStep !== undefined) ?
									this.perfData.conservative.freqStep : '-'),
						]),
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left' }, _("down_threshold")),
							E('td', { 'id': 'CDownThreshold', 'class': 'td left' },
								this.perfData.conservative.downThreshold || '-'),
						]),
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left', 'style':'min-width:33%' }, _("sampling_down_factor")),
							E('td', { 'id': 'CSmpDownFactor', 'class': 'td left' },
								this.perfData.conservative.smpDownFactor || '-'),
						]),
					]);
				};
			};
			if(cpuTable.childNodes.length === 1){
				cpuTable.append(
					E('tr', { 'class': 'tr placeholder' },
						E('td', { 'class': 'td' },
							E('em', {}, _('No performance data...'))
						)
					)
				);
			};
			let tables = [ cpuTable ];
			if(ondemandTable) {
				tables.push(
					E('h3', {}, _("Ondemand tunables")),
					ondemandTable
				);
			};
			if(conservativeTable) {
				tables.push(
					E('h3', {}, _("Conservative tunables")),
					conservativeTable,
				);
			};
			return E(tables);
		},
	}),

	CBIBlockInitButton: form.Value.extend({
		__name__ : 'CBI.BlockInitButton',

		__init__(map, section, ctx) {
			this.map      = map;
			this.section  = section;
			this.ctx      = ctx;
			this.optional = true;
			this.rmempty  = true;
		},

		renderWidget(section_id, option_index, cfgvalue) {
			this.ctx.initButton = E('button', {
				'class': (!this.ctx.initStatus) ? btnStyleDisabled : btnStyleEnabled,
				'click': ui.createHandlerFn(this, () => {
					return this.ctx.handleServiceAction(
						(!this.ctx.initStatus) ? 'enable' : 'disable'
					).then(success => {
						if(!success) {
							return;
						};
						if(!this.ctx.initStatus) {
							this.ctx.initButton.textContent = _('Enabled');
							this.ctx.initButton.className   = btnStyleEnabled;
							this.ctx.initStatus             = true;
						} else {
							this.ctx.initButton.textContent = _('Disabled');
							this.ctx.initButton.className   = btnStyleDisabled;
							this.ctx.initStatus             = false;
						};
					});
				}),
			}, (!this.ctx.initStatus) ? _('Disabled') : _('Enabled'));

			return E([
				E('label', { 'class': 'cbi-value-title', 'for': 'initButton' },
					_('Run at startup')
				),
				E('div', { 'class': 'cbi-value-field' }, [
					E('div', {}, this.ctx.initButton),
					E('input', {
						'id'  : 'initButton',
						'type': 'hidden',
					}),
				]),
			]);
		},
	}),

	freqValidate(section_id, value, slave_elem, max=false) {
		let slaveValue = slave_elem.formvalue(section_id);
		if(value === '' || slaveValue === '') {
			return true;
		};
		value      = Number(value);
		slaveValue = Number(slaveValue);
		if((max && value >= slaveValue) || (!max && value <= slaveValue)) {
			return true;
		};
		return `${_('Frequency value must not be')} ${max ? _('lower') : _('higher')} ${_('than the')} "${slave_elem.title}"!`;
	},

	load() {
		return Promise.all([
			this.getInitStatus(),
			this.callCpuPerf(),
			uci.load(this.appName),
		]).catch(e => {
			ui.addNotification(null, E('p', _('An error has occurred') + ': %s'.format(e.message)));
		});
	},

	render(data) {
		if(!data) {
			return;
		};

		this.initStatus      = data[0];
		let cpuPerfDataArray = data[1];
		let cpuDataArray     = cpuPerfDataArray.cpus || {};

		let s, o;
		let m = new form.Map(this.appName,
			_('CPU Performance'),
			_('CPU performance management.'));

		/* Status */

		s = m.section(form.NamedSection, 'config', 'main');
		o = s.option(this.CBIBlockPerf, this, cpuPerfDataArray);

		/* Performance managment */

		s = m.section(form.NamedSection, 'config', 'main',
			_("Performance managment"));

		// enabled
		o = s.option(form.Flag, 'enabled',
			_('Enable'));
		o.rmempty = false;

		// init button
		o = s.option(this.CBIBlockInitButton, this);

		/* Ondemand governor */

		s = m.section(form.NamedSection, 'ondemand', 'governor',
			_("Ondemand governor"));

		// up_threshold
		o = s.option(form.Value,
			'up_threshold', _('up_threshold'),
			_('If the estimated CPU load is above this value (in percent), the governor will set the frequency to the maximum value.')
		);
		o.rmempty     = true;
		o.optional    = true;
		o.placeholder = '1-100';
		o.datatype    = 'and(integer,range(1,100))';

		// ignore_nice_load
		o = s.option(form.Flag,
			'ignore_nice_load', _('ignore_nice_load'),
			_('If checked, it will cause the CPU load estimation code to treat the CPU time spent on executing tasks with "nice" levels greater than 0 as CPU idle time.')
		);
		o.rmempty  = true;
		o.optional = true;

		// sampling_down_factor
		o = s.option(form.Value,
			'sampling_down_factor', _('sampling_down_factor'),
			_('Frequency decrease deferral factor.')
		);
		o.rmempty     = true;
		o.optional    = true;
		o.placeholder = '1-100';
		o.datatype    = 'and(integer,range(1,100))';

		/* Conservative governor*/

		s = m.section(form.NamedSection, 'conservative', 'governor',
			_("Conservative governor"));

		// freq_step
		o = s.option(form.Value,
			'freq_step', _('freq_step'),
			_('Frequency step in percent of the maximum frequency the governor is allowed to set.')
		);
		o.rmempty     = true;
		o.optional    = true;
		o.placeholder = '1-100';
		o.datatype    = 'and(integer,range(1,100))';

		// down_threshold
		o = s.option(form.Value,
			'down_threshold', _('down_threshold'),
			_('Threshold value (in percent) used to determine the frequency change direction.')
		);
		o.rmempty     = true;
		o.optional    = true;
		o.placeholder = '1-100';
		o.datatype    = 'and(integer,range(1,100))';

		// sampling_down_factor
		o = s.option(form.Value,
			'sampling_down_factor', _('sampling_down_factor'),
			_('Frequency decrease deferral factor.')
		);
		o.rmempty     = true;
		o.optional    = true;
		o.placeholder = '1-10';
		o.datatype    = 'and(integer,range(1,10))';

		/* CPUs settings */

		let sections = uci.sections(this.appName, 'cpu');

		if(sections.length == 0) {
			s = m.section(form.NamedSection, 'config', 'main');
			o = s.option(form.DummyValue, '_dummy');
			o.rawhtml = true;
			o.default = '<label class="cbi-value-title"></label><div class="cbi-value-field"><em>' +
				_('CPU performance scaling not available...') +
				'</em></div>';
		} else {
			for(let section of sections) {
				let sectionName = section['.name'];
				let cpuNum      = Number(sectionName.replace('cpu', ''));
				let o;
				let s = m.section(form.NamedSection, sectionName, 'cpu',
					_('CPU') + ' ' + cpuNum);

				if(cpuDataArray[cpuNum]) {
					if(cpuDataArray[cpuNum].sAvailGovernors &&
					   cpuDataArray[cpuNum].sAvailGovernors.length > 0) {

						// scaling_governor
						o = s.option(form.ListValue,
							'scaling_governor', _('Scaling governor'),
							_('Scaling governors implement algorithms to estimate the required CPU capacity.')
						);
						o.rmempty  = true;
						o.optional = true;
						cpuDataArray[cpuNum].sAvailGovernors.forEach(e => o.value(e));
					};

					if(cpuDataArray[cpuNum].sMinFreq && cpuDataArray[cpuNum].sMaxFreq &&
						cpuDataArray[cpuNum].minFreq && cpuDataArray[cpuNum].maxFreq) {

						let minFreq, maxFreq;

						if(cpuDataArray[cpuNum].sAvailFreqs &&
						   cpuDataArray[cpuNum].sAvailFreqs.length > 0) {
							let availFreqs = cpuDataArray[cpuNum].sAvailFreqs.map(e =>
								[ e, this.freqFormat(e) ]
							);

							// scaling_min_freq
							minFreq = s.option(form.ListValue,
								'scaling_min_freq', _('Minimum scaling frequency'),
								_('Minimum frequency the CPU is allowed to be running.') +
									' ('  + _('default value:') + ' <code>' +
									this.freqFormat(cpuDataArray[cpuNum].minFreq) + '</code>).'
							);
							minFreq.rmempty  = true;
							minFreq.optional = true;

							// scaling_max_freq
							maxFreq = s.option(form.ListValue,
								'scaling_max_freq', _('Maximum scaling frequency'),
								_('Maximum frequency the CPU is allowed to be running.') +
									' ('  + _('default value:') + ' <code>' +
									this.freqFormat(cpuDataArray[cpuNum].maxFreq) + '</code>).'
							);
							maxFreq.rmempty  = true;
							maxFreq.optional = true;

							availFreqs.forEach(e => {
								minFreq.value(e[0], e[1]);
								maxFreq.value(e[0], e[1]);
							});

						} else {

							// scaling_min_freq
							minFreq = s.option(form.Value,
								'scaling_min_freq', `${_('Minimum scaling frequency')} (${_('KHz')})`,
								_('Minimum frequency the CPU is allowed to be running.') +
									' ('  + _('default value:') + ' <code>' +
									cpuDataArray[cpuNum].minFreq + '</code>).'
							);
							minFreq.rmempty     = true;
							minFreq.optional    = true;
							minFreq.datatype    = `and(integer,range(${cpuDataArray[cpuNum].minFreq},${cpuDataArray[cpuNum].maxFreq}))`;
							minFreq.placeholder = `${cpuDataArray[cpuNum].minFreq}-${cpuDataArray[cpuNum].maxFreq} ${_('KHz')}`;

							// scaling_max_freq
							maxFreq = s.option(form.Value,
								'scaling_max_freq', `${_('Maximum scaling frequency')} (${_('KHz')})`,
								_('Maximum frequency the CPU is allowed to be running.') +
									' ('  + _('default value:') + ' <code>' +
									cpuDataArray[cpuNum].maxFreq + '</code>).'
							);
							maxFreq.rmempty     = true;
							maxFreq.optional    = true;
							maxFreq.datatype    = `and(integer,range(${cpuDataArray[cpuNum].minFreq},${cpuDataArray[cpuNum].maxFreq}))`;
							maxFreq.placeholder = `${cpuDataArray[cpuNum].minFreq}-${cpuDataArray[cpuNum].maxFreq} ${_('KHz')}`;
						};

						minFreq.validate = L.bind(
							function(section_id, value) {
								return this.freqValidate(section_id, value, maxFreq, false);
							},
							this
						);
						maxFreq.validate = L.bind(
							function(section_id, value) {
								return this.freqValidate(section_id, value, minFreq, true);
							},
							this
						);
					};
				};

				if(!cpuDataArray[cpuNum] ||
				   !(cpuDataArray[cpuNum].sAvailGovernors &&
				   cpuDataArray[cpuNum].sAvailGovernors.length > 0) &&
				   !(cpuDataArray[cpuNum].sMinFreq && cpuDataArray[cpuNum].sMaxFreq &&
					 cpuDataArray[cpuNum].minFreq && cpuDataArray[cpuNum].maxFreq)) {
					o         = s.option(form.DummyValue, '_dummy');
					o.rawhtml = true;
					o.default = '<label class="cbi-value-title"></label><div class="cbi-value-field"><em>' +
						_('Performance scaling not available for this CPU...') +
						'</em></div>';
				};
			};
		};

		let mapPromise = m.render();
		mapPromise.then(node => {
			node.classList.add('fade-in');
			poll.add(L.bind(this.updateCpuPerfData, this));
		});
		return mapPromise;
	},

	handleSaveApply(ev, mode) {
		return this.handleSave(ev).then(() => {
			ui.changes.apply(mode == '0');
			window.setTimeout(() => this.serviceRestart(), 3000);
		});
	},
});
