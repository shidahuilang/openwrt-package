'use strict';
'require view';
'require dom';
'require uci';
'require fs';
'require ui';
'require rpc';
'require form';
'require poll';


/*
	Copyright (c) 2024 Rafał Wabik - IceG - From eko.one.pl forum
	
	Licensed to the GNU General Public License v3.0.
	
	
	Transfer statistics from easyconfig available in LuCI JS. 
	Package is my simplified conversion.
	You are using a development version of package.
	
	More information on <https://eko.one.pl/?p=easyconfig>.
*/



document.querySelector('head').appendChild(E('link', {
	'rel': 'stylesheet',
	'type': 'text/css',
	'href': L.resource('view/transfer/statistics.css')
}));


var callLuciDHCPLeases = rpc.declare({
	object: 'luci-rpc',
	method: 'getDHCPLeases',
	expect: { '': {} }
});


function tdata_bar(value, max, byte) {
var pg = document.querySelector('#idtraffic_today_progress1'),
	vn = parseInt(value) || 0,
	mn = parseInt(max) || 100,
	fv = byte ? String.format('%1024.2mB', value) : value,
	fm = byte ? String.format('%1024.2mB', max) : max,
	pc = Math.floor((100 / mn) * vn);
		if (pc >= 85 && pc <= 95 ) 
			{
			pg.firstElementChild.style.background = 'darkorange';
			};
		if (pc >= 96 && pc <= 100) 
			{
			pg.firstElementChild.style.background = 'red';
			};
pg.firstElementChild.style.width = pc + '%';
pg.setAttribute('title', '%s / %s (%d%%)'.format(fv, fm, pc));
pg.firstElementChild.style.animationDirection = "reverse";
}


function pdata_bar(value, max, byte) {
var pg = document.querySelector('#idtraffic_currentperiod_progress1'),
	vn = parseInt(value) || 0,
	mn = parseInt(max) || 100,
	fv = byte ? String.format('%1024.2mB', value) : value,
	fm = byte ? String.format('%1024.2mB', max) : max,
	pc = Math.floor((100 / mn) * vn);
		if (pc >= 85 && pc <= 95 ) 
			{
			pg.firstElementChild.style.background = 'darkorange';
			};
		if (pc >= 96 && pc <= 100) 
			{
			pg.firstElementChild.style.background = 'red';
			};
pg.firstElementChild.style.width = pc + '%';
pg.setAttribute('title', '%s / %s (%d%%)'.format(fv, fm, pc));
pg.firstElementChild.style.animationDirection = "reverse";
}



function formatDate(d) {
	function z(n){return (n<10?'0':'')+ +n;}
	return d.getFullYear() + '' + z(d.getMonth() + 1) + '' + z(d.getDate());
}

function formatDateWithoutDay(d) {
	function z(n){return (n<10?'0':'')+ +n;}
	return d.getFullYear() + '' + z(d.getMonth() + 1);
}


function formatDateTime(s) {
	if (s.length == 14) {
		return s.replace(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/, "$1-$2-$3 $4:$5:$6");
	} else if (s.length == 12) {
		return s.replace(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/, "$1-$2-$3 $4:$5");
	} else if (s.length == 8) {
		return s.replace(/(\d{4})(\d{2})(\d{2})/, "$1-$2-$3");
	} else if (s.length == 6) {
		return s.replace(/(\d{4})(\d{2})/, "$1-$2");
	}
	return s;
}


function lastDays(cnt,d) {
	d = +(d || new Date());
	var days = [];
	var i=cnt;
	while (i--) {
		days.push(formatDate(new Date(d-=8.64e7)));
	}
	return days;
}

function currentPeriod(start) {
	var d = new Date();
	var days = [];
	var i=31;
	d.setDate(d.getDate() + 1);
	while (i--) {
		var nd = new Date(d-=8.64e7);
		days.push(formatDate(nd));
		if (nd.getDate() == start) {
			return days;
		}
	}
	return days;
}

function formatDatelP(d) {
    var year = d.getFullYear().toString();
    var month = (d.getMonth() + 1 < 10 ? '0' : '') + (d.getMonth() + 1).toString();
    var day = (d.getDate() < 10 ? '0' : '') + d.getDate().toString();
    return year + month + day;
}

function lastPeriod(d) {
    const todayDate = new Date();
    const year = todayDate.getFullYear();
    const month = todayDate.getMonth() + 1;
    const daysInMonth = new Date(year, month, 0).getDate();
    const daysInPreviousMonth = new Date(year, month - 1, 0).getDate();

    var startDay = Math.min(d, daysInMonth);
    startDay = Math.max(1, startDay);

    const dates = [];

    for (var i = startDay; i >= 1; i--) {
        const currentDay = i < 10 ? '0' + i : '' + i;
        const date = `${year}${month < 10 ? '0' + month : month}${currentDay}`;
        dates.push(date);
    }

    if (dates.length < daysInMonth && month > 1) {
        for (var i = daysInPreviousMonth; dates.length < daysInMonth; i--) {
            const currentDay = i < 10 ? '0' + i : '' + i;
            const date = `${year}${month - 1 < 10 ? '0' + (month - 1) : month - 1}${currentDay}`;
            dates.push(date);
        }
    }
    dates.pop();
    dates.shift();
    return dates;
}

function bytesToSize(bytes) {
	var sizes = ['', 'KiB', 'MiB', 'GiB', 'TiB'];
	if (bytes == 0) return '0';
	var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
	var dm = 0;
	if (i == 2) {dm = 1;}
	if (i > 2) {dm = 3;}
	return parseFloat((bytes / Math.pow(1024, i)).toFixed(dm)) + ' ' + sizes[i];
}

function json2ubuscall(input) {
  const output = [];
  const owan = input["wan"];
  if (owan) {
    for (const key in owan) {
      if (key !== "first_seen" && key !== "type" && key !== "last_seen") {
        const ifname = key;
        const ostats = owan[ifname];
        for (const date in ostats) {
          if (date.match(/^\d{8}$/)) {
            const stats = ostats[date];
            output.push({
              ifname,
              date,
              tx: stats.total_tx,
              rx: stats.total_rx
            });
          }
        }
      }
    }
  }
  return { statistics: output };
}


return view.extend({
	load: function() {
		return Promise.all([
			callLuciDHCPLeases(),
			L.resolveDefault(L.uci.load('easyconfig_transfer'), {})
		]);
	},

	handleRfresh: function(ev) {
		fs.exec_direct('/usr/bin/easyconfig_statistics.sh');
	},

	handleRT: function(ev) {
		if (confirm(_('Do you want to clear transfer statistics data?')))
			{
			fs.write('/tmp/easyconfig_statistics.json', '{}');
			fs.exec_direct('/bin/lock', [ '-u' , '/var/lock/easyconfig_statistics.lock' ]);
			fs.remove('/etc/modem/easyconfig_statistics.json.gz');
			fs.exec('sleep 2');
			fs.remove('/etc/modem/easyconfig_statistics.json');
		}

	},

	handleGo: function(ev) {

		var elem = document.getElementById('mr');
		var vN = elem.innerText;

		if (vN.includes(_('Make')) == true)
		{
			fs.exec_direct('/bin/lock', [ '-u' , '/var/lock/easyconfig_statistics.lock' ]);
			//fs.remove('/etc/modem/easyconfig_statistics.json.gz');
			fs.exec('sleep 2');
			fs.remove('/etc/modem/easyconfig_statistics.json');
			fs.exec('sleep 2');
			fs.exec_direct('/bin/cp', [ '/tmp/easyconfig_statistics.json' , '/etc/modem' ]);			
		}

		if (vN.includes(_('Restore')) == true)
		{
			fs.exec_direct('/bin/lock', [ '-u' , '/var/lock/easyconfig_statistics.lock' ]);
			//fs.remove('/etc/modem/easyconfig_statistics.json.gz');
			fs.exec('sleep 2');
			fs.remove('/tmp/easyconfig_statistics.json');
			fs.exec('sleep 2');
			fs.exec_direct('/bin/cp', [ '/etc/modem/easyconfig_statistics.json' , '/tmp' ]);
			fs.exec('sleep 2');
			fs.remove('/etc/modem/easyconfig_statistics.json');
		}
	},


	render: function(stat) {

		var store = '-';
		var total = '0';
		var estatus;
		var group;

		var table =
			E('table', { 'class': 'table lases' , 'id' : 'trTable' }, [
				E('tr', { 'class': 'tr table-titles' }, [
					E('th', { 'class': 'th' }, _('MAC Address')),
					E('th', { 'class': 'th' }, _('Hostname')),
					E('th', { 'class': 'th' }, _('First Seen')),
					E('th', { 'class': 'th' }, _('Last Seen')), 
					E('th', { 'class': 'th' }, _('Downloaded')),
					E('th', { 'class': 'th' }, _('Uploaded'))
				])
			]);

		poll.add(function() {
       			return fs.trimmed('/tmp/easyconfig_statistics.json').then(function(data) {
            			if (data.length > 1) {
                			var jsonData = JSON.parse(data);
					const output = json2ubuscall(jsonData);
					var datacnv = JSON.stringify(output, null, 2);
					var json = JSON.parse(datacnv);

                        var sections = uci.sections('easyconfig_transfer');
                        var data_traffic_cycle = sections[1].cycle;
                        var data_traffic_warning_unit = sections[1].warning_unit;
			var data_traffic_warning_cycle = sections[1].warning_cycle;
                        var data_traffic_warning_value = sections[1].warning_value;
			var usage_bar_view = sections[1].warning_enabled;
			var hidden_data_value = sections[1].hidden_data;
			var wan_view = sections[1].wan_view;
			var zero_view = sections[1].zero_view;
			var mac_list = Array.isArray(sections[1].host_names) ? sections[1].host_names : [];

			var macs_list = [];


			for (var i = 0; i < mac_list.length; i++) 
			{
              			macs_list.push(mac_list[i]);
			}

			var traffic_cycle = data_traffic_cycle;

			var now = new Date();
			var day = now.getDate();
			var month = now.getMonth();
			var year = now.getFullYear();
			now = new Date(year, month, day);
			if (day <= data_traffic_cycle) {
				var newdate = new Date(year, month, data_traffic_cycle);
			} else {
				var newdate = month == 11 ? new Date(year + 1, 0, data_traffic_cycle) : new Date(year, month + 1, data_traffic_cycle);
			}
			var timediff = Math.abs(newdate.getTime() - now.getTime());
			var diffdays = Math.ceil(timediff / (1000 * 3600 * 24));

                        if (data_traffic_warning_unit == "m") {
                            var traffic_limit = 1024 * 1024 * data_traffic_warning_value;
                        }
                        if (data_traffic_warning_unit == "g") {
                            var traffic_limit = 1024 * 1024 * 1024 * data_traffic_warning_value;
                        }
                        if (data_traffic_warning_unit == "t") {
                            var traffic_limit = 1024 * 1024 * 1024 * 1024 * data_traffic_warning_value;
                        }
                        
                        var traffic_cycle = data_traffic_cycle;

			var today = new Array(formatDate(new Date));
			var yesterday = lastDays(1);
			var last7d = lastDays(7);
			var last30d = lastDays(30);

			var current_period = currentPeriod(traffic_cycle);
			var last_period = lastPeriod(traffic_cycle);

			var traffic_today = 0;
			var traffic_today_rx = 0;
			var traffic_today_tx = 0;
			var traffic_yesterday = 0;
			var traffic_last7d = 0;
			var traffic_last30d = 0;
			var traffic_total = 0;
			var traffic_currentperiod = 0;
			var traffic_lastperiod = 0;
			var total_since = '';
			var traffic = [];
			if (json.statistics.length > 0) {
				traffic = json.statistics;
			}
			for (var idx = 0; idx < traffic.length; idx++) {
				var t_date = traffic[idx].date;
				var t_rx = traffic[idx].rx;
				var t_tx = traffic[idx].tx;
				var t_value = (parseInt(t_rx) || 0) + (parseInt(t_tx) || 0);
				if (total_since == '') {total_since = t_date;}

				if (t_date == today[0]) {
					traffic_today += parseInt(t_value);
					traffic_today_rx += parseInt(t_rx);
					traffic_today_tx += parseInt(t_tx);
				}

				if (t_date == yesterday[0]) {
					traffic_yesterday += parseInt(t_value);
				}

				for (var idx1 = 0; idx1 < 7; idx1++) {
					if (t_date == last7d[idx1]) {
						traffic_last7d += parseInt(t_value);
					}
				}

				for (var idx1 = 0; idx1 < 30; idx1++) {
					if (t_date == last30d[idx1]) {
						traffic_last30d += parseInt(t_value);
					}
				}

				for (var idx1 = 0; idx1 < current_period.length; idx1++) {
					if (t_date == current_period[idx1]) {
						traffic_currentperiod += parseInt(t_value);
					}
				}

				for (var idx1 = 0; idx1 < last_period.length; idx1++) {
					if (t_date == last_period[idx1]) {
						traffic_lastperiod += parseInt(t_value);
					}
				}

				traffic_total += parseInt(t_value);
				if (total_since > t_date) {total_since = t_date;}
			}

			if (total_since) {
				var traffic_total_since = '(' + _('from') + ' ' + formatDateTime(total_since) + ')';
			} else {
				var traffic_total_since = '';
			}

			var ntraffic_currentperiod = bytesToSize(traffic_currentperiod);
			var ntraffic_currentperiod_projected = bytesToSize((traffic_currentperiod / current_period.length) * (current_period.length + diffdays - 1));
			var ntraffic_lastperiod = bytesToSize(traffic_lastperiod);

			if (usage_bar_view === "1") {
				if (data_traffic_warning_cycle == 'p') {
					var percent = parseInt((traffic_currentperiod * 100) / traffic_limit);
					var traffic_currentperiod_progress = ' (' + percent + '% ' + _('out of') + ' ' + bytesToSize(traffic_limit) + ')';
					if (percent > 100) {
						var percent = 100;
						estatus = bytesToSize((traffic_currentperiod - traffic_limit));
						ui.addNotification(null, E('p', _('You have exceeded your available transfer by over')+' '+estatus), 'error');
						poll.stop();
						var traffic_currentperiod = traffic_limit;
					}
                        		var view = document.getElementById("idtraffic_currentperiod");
                        		view.innerHTML = ntraffic_currentperiod + ' ' + traffic_currentperiod_progress;
					pdata_bar(traffic_currentperiod, traffic_limit, true);
					var viewbar = document.getElementById('idtraffic_currentperiod_progress');
					viewbar.style.display = "block";
					document.getElementById('idtraffic_currentperiod_progress').classList.remove('hidden');
				}
				if (data_traffic_warning_cycle == 'd') {
					var percent = parseInt((traffic_today * 100) / traffic_limit);
					var traffic_today_progress = ' (' + percent + '% ' + _('out of') + ' ' + bytesToSize(traffic_limit) + ')';
					if (percent > 100) {
						var percent = 100;
						estatus = bytesToSize((traffic_today - traffic_limit));
						ui.addNotification(null, E('p', _('You have exceeded your available transfer by over')+' '+estatus), 'error');
						poll.stop();
						var traffic_today = traffic_limit;
					}
                        		var view = document.getElementById("idtraffic_currentperiod");
                        		view.innerHTML = ntraffic_currentperiod + ' ' + traffic_today_progress;
					tdata_bar(traffic_today, traffic_limit, true);
					var viewbar = document.getElementById('idtraffic_today_progress');
					viewbar.style.display = "block";
					document.getElementById('idtraffic_today_progress').classList.remove('hidden');
				}
			} else {
				var viewrem = document.getElementById('idremaining_transfer_gl');
				viewrem.style.display = "none";
				var traffic_currentperiod_progress = '';
				var traffic_today_progress = '';

                        	var view = document.getElementById("idtraffic_currentperiod");
                        	view.innerHTML = ntraffic_currentperiod;
			}

			var view = document.getElementById("idtraffic_today");
			view.innerHTML = bytesToSize(traffic_today);

			var view = document.getElementById("idtraffic_yesterday");
			view.innerHTML = bytesToSize(traffic_yesterday);

			var view = document.getElementById("idtraffic_last7d");
			view.innerHTML = bytesToSize(traffic_last7d);

			var view = document.getElementById("idtraffic_last30d");
			view.innerHTML = bytesToSize(traffic_last30d);

                        var view = document.getElementById("idtraffic_total");
                        view.innerHTML = bytesToSize(traffic_total) + ' ' + traffic_total_since;

                        var view = document.getElementById("idtraffic_currentperiod_daysleft");
                        view.innerHTML = diffdays;

                        var view = document.getElementById("idtraffic_currentperiod_projected");
                        view.innerHTML = ntraffic_currentperiod_projected;

                        var view = document.getElementById("idtraffic_lastperiod");
                        view.innerHTML = ntraffic_lastperiod;

                        var view = document.getElementById("idremaining_transfer");
			if (data_traffic_warning_cycle == 'p') {
			view.innerHTML = diffdays > 0 ? bytesToSize(traffic_limit - traffic_currentperiod) + ' (' + _('approximately remains') + ' ' + bytesToSize((traffic_limit - traffic_currentperiod) / diffdays) + ' ' + _('per day') + ')' : bytesToSize(traffic_limit - traffic_currentperiod);
			}
			if (data_traffic_warning_cycle == 'd') {
                        view.innerHTML = bytesToSize(traffic_limit - traffic_today);
			}

			var rows = [];
			var sortedData = [];

			var includeWan = wan_view;
			var hideZeros = zero_view;
			var leases = Array.isArray(stat[0].dhcp_leases) ? stat[0].dhcp_leases : [];

			for (var mac in jsonData) {
    			if (jsonData.hasOwnProperty(mac) && (includeWan == "1" || !mac.includes("wan"))) {

        			var deviceData = jsonData[mac];
        			var totalTX = 0;
        			var totalRX = 0;

        			for (var key in deviceData) {
            				if (key.startsWith("phy") && key.includes("ap")) {
                				var phyData = deviceData[key];
                				for (var date in phyData) {
                    					if (current_period.includes(date)) {
                        					var data = phyData[date];
                        					totalTX += data.total_tx || 0;
                        					totalRX += data.total_rx || 0;
                    					}
                				}
            				}

            				if (!key.startsWith("phy")) {
                				var phyData = deviceData[key];
                				for (var date in phyData) {
                    					if (current_period.includes(date)) {
                        					var data = phyData[date];
                        					totalTX += data.total_tx || 0;
                        					totalRX += data.total_rx || 0;
                    					}
                				}
            				}
        			}


        			var modifiedMac = mac.replaceAll("_", ":").toUpperCase();

				if (leases.length > 0) {
    					var dhcpname = deviceData.dhcpname || '';
    
    					for (var i = 0; i < leases.length || i < macs_list.length; i++) {
        				if (i < leases.length && leases[i].macaddr === modifiedMac) {
            					dhcpname += " (" + leases[i].ipaddr + ')';
        				}
					if (macs_list.length > 0) {
        				if (i < macs_list.length && macs_list[i].split(';')[0] === modifiedMac) {
            					dhcpname = macs_list[i].split(';')[1] + " (" + leases[i].ipaddr + ")";
            					break;
        				}
					}
    				}
			}
		if ((hideZeros == "1" && totalTX > 0 && totalRX > 0) || (hideZeros == "0")) {	
        		sortedData.push({
            			mac: modifiedMac,
            			dhcpname: dhcpname,
            			first_seen: formatDateTime(deviceData.first_seen) || '-',
            			last_seen: formatDateTime(deviceData.last_seen) || '-',
            			totalTX: totalTX,
            			totalRX: totalRX
        			});
			}
    		}
}

			sortedData.sort((a, b) => b.totalTX - a.totalTX);

			for (var i = 0; i < sortedData.length; i++) {
    				var device = sortedData[i];
    				var mac = '';
    				var dhcpname = '';

    			if (hidden_data_value === 'mh') {
        			mac = device.mac ? device.mac.replace(/[^:]/g, '#') : '';
        			dhcpname = device.dhcpname ? device.dhcpname.replace(/[a-zA-Z0-9]/g, '#') : '';
    			} else if (hidden_data_value === 'm') {
        			mac = device.mac ? device.mac.replace(/[^:]/g, '#') : '';
        			dhcpname = device.dhcpname;
    			} else if (hidden_data_value === 'h') {
        			mac = device.mac;
        			dhcpname = device.dhcpname ? device.dhcpname.replace(/[a-zA-Z0-9]/g, '#') : '';
    			} else {
        			mac = device.mac;
        			dhcpname = device.dhcpname;
    			}

    		rows.push([
        		mac,
        		(dhcpname.length > 1) ? dhcpname : '-',
        		device.first_seen,
        		device.last_seen,
        		bytesToSize(device.totalTX),
        		bytesToSize(device.totalRX)
    			]);
		}
		

}

	cbi_update_table(table, rows, E('em', { class: 'spinning' }, _('There are currently no data to show...')));				
	});
});
	
	var group = 1;

		return E([], [
			E('h2', _('Transfer')),
			E('div', { 'class': 'cbi-map-descr' }, _('User interface for easyconfig scripts estimating transfer consumption. More information on the %seko.one.pl forum%s.').format('<a href="https://eko.one.pl/?p=easyconfig" target="_blank">', '</a>')),
			E('p'),
			E('div', { 'class': 'ifacebox', 'style': 'display:flex' }, [
			E('strong', _('Info')),
					E('label', {}, _('Calculations may differ from the operator indications')),
			]),
			E('p'),

			E('h3', _('Transfer usage statistics')),
				E('table', { 'class': 'table' }, [
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [_('Today'),]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_today' }, [ _('-') ]), 
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [_('Yesterday'),]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_yesterday' }, [ _('-') ]), 
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [_('Last 7 days'),]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_last7d' }, [ _('-') ]), 
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [_('Last 30 days'),]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_last30d' }, [ _('-') ]), 
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('Total')]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_total' }, [ _('-') ]),
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('Days until the end of the billing period')]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_currentperiod_daysleft' }, [ _('-') ]),
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('Current billing period')]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_currentperiod' }, [ _('-') ]),
					]),
						E('tr', { 'class': 'tr', 'id': 'idremaining_transfer_gl' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [_('Estimated remaining transfer'),]),
						E('td', { 'class': 'td left', 'id': 'idremaining_transfer' }, [ _('-') ]), 
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('Expected data usage for the current period')]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_currentperiod_projected' }, [ _('-') ]),
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('Previous billing period')]),
						E('td', { 'class': 'td left', 'id': 'idtraffic_lastperiod' }, [ _('-') ]),
					])
				]),
				E('div', { 
					'class': 'controls',
					'style': 'display: none;',
					'id': 'idtraffic_today_progress'
				}, [
				E('div', {}, [
					E('label', {}, _('Estimated data usage') + ' (' + _('per day') + ')' + ':'),
					E('div', { 'class': 'cbi-progressbar', 'title': _('unknown'), 'id': 'idtraffic_today_progress1' }, E('div', {}, [ '\u00a0' ]))
					])
				]),

				E('div', {
					'class': 'controls',
					'style': 'display: none;',
					'id': 'idtraffic_currentperiod_progress'
				}, [
				E('div', {}, [
					E('label', {}, _('Estimated data usage') + ' (' + _('per period') + ')' + ':'),
					E('div', { 'class': 'cbi-progressbar', 'title': _('unknown'), 'id': 'idtraffic_currentperiod_progress1' }, E('div', {}, [ '\u00a0' ]))
					])
				]),


				E('p'),

				E('div', { 'class': 'right' }, [
					E('button', {
						'class': 'cbi-button cbi-button-remove',
						'id': 'rst',
						'click': ui.createHandlerFn(this, 'handleRT')
					}, [ _('Reset data') ]),
					'\xa0\xa0\xa0',
						E('span', { 'class': 'diag-action' }, [
							group ? new ui.ComboButton('mcopy', {
								'mcopy': '%s %s'.format(_('Make'), _('a backup')),
								'rcopy': '%s %s'.format(_('Restore'), _('a backup')),
							}, {
								'click': ui.createHandlerFn(this, 'handleGo'),
								'id': 'mr',
								'classes': {
									'mcopy': 'cbi-button cbi-button-action',
									'rcopy': 'cbi-button cbi-button-action',
								},
								'id': 'mr',
							}).render() : E('button', {
								'class': 'cbi-button cbi-button-action',
								'id': 'mr',
								'click': ui.createHandlerFn(this, 'handleGo')
							}, [ _('Make a backup') ]),
						]),
					'\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-add',
						'id': 'rfresh',
						'click': ui.createHandlerFn(this, 'handleRfresh')
					}, [ _('Refresh') ]),
			]),

			E('h4', _('Clients')),
			E('div', { 'class': 'cbi-map-descr' }, _('Statistics from the current billing period.')),
			table
		]);
	},

	handleSave: null,
	handleSaveApply:null,
	handleReset: null
});
