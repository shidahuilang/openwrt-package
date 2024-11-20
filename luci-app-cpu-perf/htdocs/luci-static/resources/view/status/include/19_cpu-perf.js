'use strict';
'require baseclass';
'require rpc';

return baseclass.extend({
	title      : _('CPU Performance'),

	callCpuPerf: rpc.declare({
		object: 'luci.cpu-perf',
		method: 'getCpuPerf',
		expect: { '': {} }
	}),

	freqFormat(freq) {
		if(!freq) {
			return '-';
		};
		return (freq >= 1e6) ?
			(freq / 1e6) + ' ' + _('GHz')
		:
			(freq / 1e3) + ' ' + _('MHz');
	},

	load() {
		return L.resolveDefault(this.callCpuPerf(), null);
	},

	render(data) {
		if(!data) return;

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

		if(data.cpus) {
			for(let i of Object.values(data.cpus)) {
				cpuTable.append(
					E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'data-title': cpuTableTitles[0] }, _('CPU') + ' ' + i.number),
						E('td', { 'class': 'td left', 'data-title': cpuTableTitles[1] },
							(i.sCurFreq) ? this.freqFormat(i.sCurFreq) : this.freqFormat(i.curFreq)
						),
						E('td', { 'class': 'td left', 'data-title': cpuTableTitles[2] },
							(i.sMinFreq) ? this.freqFormat(i.sMinFreq) : this.freqFormat(i.minFreq)
						),
						E('td', { 'class': 'td left', 'data-title': cpuTableTitles[3] },
							(i.sMaxFreq) ? this.freqFormat(i.sMaxFreq) : this.freqFormat(i.maxFreq)
						),
						E('td', { 'class': 'td left', 'data-title': cpuTableTitles[4] }, i.governor || '-'),
					])
				);
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

		return cpuTable;
	},
});
