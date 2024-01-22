'use strict';
'require baseclass';
'require form';
'require fs';
'require view';
'require ui';
'require uci';
'require poll';
'require dom';
'require tools.widgets as widgets';


/*
	Copyright Konstantine Shevlakov <shevlakov@132lan.ru> 2023
	
	Licensed to the GNU General Public License v3.0.
	
	Thanks to Rafał Wabik - IceG https://github.com/4IceG/luci-app-3ginfo-lite for the initial codebase.
*/

return view.extend({

	load: function() {
		return L.resolveDefault(fs.exec_direct('/usr/bin/modeminfo'));
	},

	render: function(data){
		var m, s, o;
		m = new form.JSONMap(this.formdata, _('Modeminfo: Hardware'), _('Hardware and sim card info.'));
		s= m.section(form.TypedSection, '', '', null);
		s.anonymous = true;
		if (data != null) {
			try {
				var json = JSON.parse(data);
				if(!json.hasOwnProperty('error')){
					polldata: poll.add(function() {
						return L.resolveDefault(fs.exec_direct('/usr/bin/modeminfo')).then(function(res) {
							var json = JSON.parse(res);
							if (document.getElementById('device')) {
								var view = document.getElementById("device");
								if (json.device == '--') {
									view.style.display = "none";
								} else {
									view.innerHTML = String.format(json.device);
								}
							}
							if (document.getElementById('firmware')) {
								var view = document.getElementById("firmware");
								if (json.firmware == '--') {
									view.style.display = "none";
								} else {
									view.innerHTML = String.format(json.firmware);
								}
							}

							if (document.getElementById('imsi')) {
								var view = document.getElementById("imsi");
								if (json.imsi == '--') {
									view.style.display = "none";
								} else {
									view.innerHTML = String.format(json.imsi);
								}
							}

							if (document.getElementById('iccid')) {
								var view = document.getElementById("iccid");
								if (json.iccid == '--') {
									view.style.display = "none";
								} else {
									view.innerHTML = String.format(json.iccid);
								}
							}

							if (document.getElementById('imei')) {
								var view = document.getElementById("imei");
								if (json.imei == '--') {
									view.style.display = "none";
								} else {
									view.innerHTML = String.format(json.imei);
								}
							}

							if (document.getElementById('chiptemp')) {
								var view = document.getElementById("chiptemp");
								if (json.chiptemp == '--') {
									view.style.display = "none";
								} else {
									view.innerHTML = String.format(json.chiptemp+' °C');
								}
							}
						});
					});
					s.render = L.bind(function(data) {
						return E('div', { 'class': 'cbi-section' }, [
							E('table', { 'class': 'table' }, [
								E('tr', { 'class': 'tr cbi-rowstyle-2' }, [
									E('td', { 'class': 'td left', 'width': '50%' }, [ _('Device')]),
									E('td', { 'class': 'td left', 'id': 'device' }, [ '--' ]),
								]),
								E('tr', { 'class': 'tr cbi-rowstyle-1' }, [
									E('td', { 'class': 'td left', 'width': '50%' }, [ _('Firmware')]),
									E('td', { 'class': 'td left', 'id': 'firmware' }, [ '--' ]),
								]),
								E('tr', { 'class': 'tr cbi-rowstyle-2' }, [
									E('td', { 'class': 'td left', 'width': '50%' }, [ _('IMSI')]),
									E('td', { 'class': 'td left', 'id': 'imsi' }, [ '--' ]),
								]),
								E('tr', { 'class': 'tr cbi-rowstyle-1' }, [
									E('td', { 'class': 'td left', 'width': '50%' }, [ _('ICCID')]),
									E('td', { 'class': 'td left', 'id': 'iccid' }, [ '--' ]),
								]),
								E('tr', { 'class': 'tr cbi-rowstyle-2' }, [
									E('td', { 'class': 'td left', 'width': '50%' }, [ _('IMEI')]),
									E('td', { 'class': 'td left', 'id': 'imei' }, [ '--' ]),
								]),
								E('tr', { 'class': 'tr cbi-rowstyle-1' }, [
								E('td', { 'class': 'td left', 'width': '50%' }, [ _('Chiptemp')]),
								E('td', { 'class': 'td left', 'id': 'chiptemp' }, [ '--' ]),
								])
							])
						]) }, o, this);
				}
			} catch (err) {
				ui.addNotification(null, E('p', _('Error: ') + err.message), 'error');
			}
		}
		return m.render();
	},
	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
