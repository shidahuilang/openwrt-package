'use strict';
'require dom';
'require form';
'require fs';
'require poll';
'require view';

/*
	https://github.com/tkmsst/luci-app-cellularstatus
*/

function reception_lv(v) {
	const min = -120;
	const max = -66;

	var pc = 0;
	var vn = parseInt(v) || 0;
	if (vn != 0) {
		pc = Math.floor(100 * (1 - (max - vn) / (max - min)));
	}

	var i, c;
	if (pc >= 50) {
		if (pc >= 75) {
			if (pc > 100) {
				pc = 100;
			}
			i = L.resource('icons/signal-75-100.png');
		} else {
			i = L.resource('icons/signal-50-75.png');
		}
		c = 'green';
	} else if (pc >= 25) {
		i = L.resource('icons/signal-25-50.png');
		c = 'orange';
	} else if (pc >= 10) {
		i = L.resource('icons/signal-0-25.png');
		c = 'red';
	} else {
		if (pc > 0) {
			i = L.resource('icons/signal-0.png');
		} else {
			pc = 0;
			i = L.resource('icons/signal-none.png');
		}
		c = 'grey';
	}

	return {
		per: pc,
		icon: i,
		color: c
	};
}

function signal_lv(s, v) {
	var min, max, u;

	if (s == 'rssi') {
		min = -90;
		max = -30;
		u = 'dBm';
	} else if (s == 'rsrp') {
		min = -140;
		max = -44;
		u = 'dBm';
	} else if (s == 'rsrq') {
		min = -20;
		max = -3;
		u = 'dB';
	} else if (s == 'snr') {
		min = 0;
		max = 20;
		u = 'dB';
	}

	var pc = 0;
	var vn = parseInt(v) || 0;
	if (vn != 0) {
		var pc =  Math.floor(100 * (1 - (max - vn) / (max - min)));
		pc = Math.min(Math.max(pc, 0), 100);
	}

	return {
		per: pc,
		unit: u
	};
}

const identity = ['iccid', 'imsi', 'imei', 'msisdn'];

return view.extend({
	load: function() {
		return (async function() {
			var o = {};

			for (var i = 0; i < identity.length; i++) {
				var s = await L.resolveDefault(fs.exec_direct('/sbin/uqmi', ['-d', '/dev/cdc-wdm0', '-t', '2000' ,'--get-' + identity[i]]));
				o[identity[i]] = parseInt(s.slice(1, -2)) || _('None');
			}
			o.signal = await L.resolveDefault(fs.exec_direct('/sbin/uqmi', ['-d', '/dev/cdc-wdm0', '-t', '2000', '--get-signal-info']));

			return o;
		}()).then(function(res) {
			return res;
		});
	},

	render: function(res) {
		const indicator = ['rssi', 'rsrp', 'rsrq', 'snr'];
		var m, s, o;

		m = new form.JSONMap(this.formdata, _('Cellular Network'), _('Cellular network information'));
		s = m.section(form.TypedSection, '', '', null);
		s.anonymous = true;

		pollData: poll.add(function() {
			return L.resolveDefault(fs.exec_direct('/sbin/uqmi', ['-d', '/dev/cdc-wdm0', '-t', '2000', '--get-signal-info'])).then(function(res) {
				// Signal bar
				var json = JSON.parse(res);
				var rlv = reception_lv(json.rsrp);
				var view = document.getElementById('strength');
				if (view) {
					view.innerHTML = '%s <span class="ifacebadge"><img src="%s"><span style="font-weight:bold;color:%s"> %d%%</span></span>'
					.format(json.type.toUpperCase(), rlv.icon, rlv.color, rlv.per);
				}

				// Signal value
				if (json.hasOwnProperty('rsrp')) {
					for (var i = 0; i < indicator.length; i++) {
						var view = document.getElementById(indicator[i]);
						if (view) {
							var slv = signal_lv(indicator[i], json[indicator[i]]);
							view.setAttribute('title', '%s %s'.format(json[indicator[i]], slv.unit));
							view.firstElementChild.style.width = '%d%%'.format(slv.per);
						}
					}
				}
			});
		});

		s.render = function() {
			// SIM information
			var table_sim = E('table', { 'class': 'table' });
			for (var i = 0; i < identity.length; i++) {
				table_sim.appendChild(E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left', 'width': '33%' }, [ identity[i].toUpperCase() ]),
					E('td', { 'class': 'td left' }, [ res[identity[i]] ])
				]));
			}

			// Connection status
			var json = JSON.parse(res.signal);
			var rlv = reception_lv(json.rsrp);
			var table_signal = E('table', { 'class': 'table' });
			table_signal.appendChild(E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ _('Signal strength') ]),
				E('td', { 'id': 'strength', 'class': 'td left' }, [
					json.type.toUpperCase(), ' ', E('span', { 'class': 'ifacebadge' }, [
						E('img', { 'src': rlv.icon }), E('span', { 'style': 'font-weight: bold; color: %s'.format(rlv.color) }, [ ' %d%%'.format(rlv.per) ])
					])
				])
			]));
			if (json.hasOwnProperty('rsrp')) {
				for (var i = 0; i < indicator.length; i++) {
					var slv = signal_lv(indicator[i], json[indicator[i]]);
					table_signal.appendChild(E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ indicator[i].toUpperCase() ]),
						E('td', { 'class': 'td left' }, E('div', {
							'id': indicator[i], 'class': 'cbi-progressbar', 'title': '%s %s'.format(json[indicator[i]], slv.unit)
						}, E('div', { 'style': 'width:%d%%'.format(slv.per) })))
					]));
				}
			}

			return E('div', { 'class': 'cbi-section' }, [
				E('h3', _('SIM Information')), table_sim, E('div'), E('h3', _('Current Connection Status')), table_signal
			]);
		};

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
