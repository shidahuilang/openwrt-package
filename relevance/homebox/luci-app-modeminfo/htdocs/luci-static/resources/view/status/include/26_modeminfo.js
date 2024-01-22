'use strict';                                                                                              
'require baseclass';
'require form';
'require fs';
'require ui';
'require uci';

/*
	Written by Konstantine Shevlakov at <shevlakov@132lan.ru> 2023

	Licensed to the GNU General Public License v3.0.

	Special Thanks to Vladislav Kadulin aka @Kodo-kakaku
	https://github.com/Kodo-kakaku/ to fix update overview page

*/

return baseclass.extend({
	title: _('Cellular network'),
	load: async function() {
			uci.load('modeminfo');
			return L.resolveDefault(fs.exec_direct('/usr/bin/modeminfo')).then(function(res) {
				var json = JSON.parse(res);
				var icon;
							var p = (json.csq_per);
							if (p < 0)
								icon = L.resource('icons/signal-none.png');
							else if (p == 0)
								icon = L.resource('icons/signal-none.png');
							else if (p < 10)
								icon = L.resource('icons/signal-0.png');
							else if (p < 25)
								icon = L.resource('icons/signal-0-25.png');
							else if (p < 50)
								icon = L.resource('icons/signal-25-50.png');
							else if (p < 75)
								icon = L.resource('icons/signal-50-75.png');
							else
								icon = L.resource('icons/signal-75-100.png');
							// get reg state
							var reg;
							var rg = (json.reg)
							if (rg == 0)
								reg = _('No Registration');
							else if (rg == 2 || rg == 8)
								reg = _('Searching');
							else if (rg == 3)
								reg = _('Denied');
							else if (rg == 4)
								reg = _('Unknown');
							else if (rg == 5 || rg == 7 || rg == 10)
								reg = _('Roaming');
							else
								reg = _('No Data');

							// frequency band calculator
							// frequency band calculator
							var frul;
							var frdl;
							var offset;
							var band;
							var netmode = (json.mode)
							var rfcn = (json.arfcn)
							if (netmode == "LTE") {
								if (rfcn >= 0 && rfcn <= 599) {
									var frdl = 2110;
									var frul = 1920;
									var offset = 0;
									var band = "1";
								} else if (rfcn >= 600 && rfcn <= 1199) {
									var frdl = 1930;
									var frul = 1850;
									var offset = 600;
									var band = "2";
								} else if (rfcn >= 1200 && rfcn <= 1949) {
									var frdl = 1805;
									var frul = 1710;
									var offset = 1200;
									var band = "3";
								} else if (rfcn >= 1950 && rfcn <= 2399) {
									var frdl = 2110;
									var frul = 1710;
									var offset = 1950;
									var band = "4";
								} else if (rfcn >= 2400 && rfcn <= 2469) {
									var rfdl = 869;
									var frul = 824;
									var offset = 2400;
									var band = "5";
								} else if (rfcn >= 2750 && rfcn <= 3449) {
									var frdl = 2620;
									var frul = 2500;
									var offset = 2750;
									var band = "7";
								} else if (rfcn >= 3450 && rfcn <= 3799) {
									var frdl = 925;
									var frul = 880;
									var offset = 3450;
									var band = "8";
								} else if (rfcn >= 6150 && rfcn <= 6449) {
									var frdl = 791;
									var frul = 832;
									var offset = 6150;
									var band = "20";
								} else if (rfcn >= 9210 && rfcn <= 9659) {
									var frdl = 758;
									var frul = 703;
									var offset = 9210;
									var band = "28";
								} else if (rfcn >= 9870 && rfcn <= 9919) {
									var frdl = 452.5;
									var frul = 462.5;
									var offset = 9870;
									var band = "31";
								} else if (rfcn >= 37750 && rfcn <= 38249) {
									var frdl = 2570;
									var frul = 2570;
									var offset = 37750;
									var band = "38";
								} else if (rfcn >= 38650 && rfcn <= 39649) {
									var frdl = 2300;
									var frul = 2300;
									var offset = 38650;
									var band = "40";
								} else {
									var offset = 0;
									var frdl = 0;
									var frul = 0;
									var rfcn = 0;
									var band = (rfcn);
								}
								var bwdld = (json.bwdl);
								if (bwdld == 0) {
									var bw = 1.4;
								} else if (bwdld == 1) {
									var bw = 3;
								} else if (bwdld == 2) {
									var bw = 5;
								} else if (bwdld == 3) {
									var bw = 10;
								} else if (bwdld == 4) {
									var bw = 15;
								} else if (bwdld == 5) {
									var bw = 20;
								} else {
									var bw = "";
								}
								var dlfreq = (frdl + (rfcn - offset)/10);
								var ulfreq = (frul + (rfcn - offset)/10);
							} else {
								if (rfcn >= 10562 && rfcn <= 10838) {
									var offset = 950;
									var dlfreq = (rfcn/5);
									var ulfreq = ((rfcn - offset)/5);
									var band = "IMT2100";
								} else if (rfcn >= 2937 && rfcn <= 3088) {
									var frul = 925;
									var offset = 340;
									var ulfreq = (offset + (rfcn/5));
									var dlfreq = (ulfreq - 45);
									var band = "UMTS900";
								} else if (rfcn >= 955 && rfcn <= 1023) {
									var frul = 890;
									var ulfreq = (frul + ((rfcn - 1024)/5));
									var dlfreq = (ulfreq + 45);
									var band = "DSC900";
								} else if (rfcn >= 512 && rfcn <= 885) {
									var frul = 1710;
									var ulfreq = (frul + (rfcn - 512)/5);
									var dlfreq = (ulfreq + 95);
									var band = "DCS1800";
								} else if (rfcn >= 1 && rfcn <= 124) {
									var frul = 890;
									var ulfreq = (frul + (rfcn/5));
									var dlfreq = (ulfreq + 45);
									var band = "GSM900";
								} else {
									var ulfreq = 0;
									var dlfreq = 0;
									var band = (rfcn);
								}
							}
							var carrier = "";
							var bcc;
							var freq;
							var distance;
							var lactac;
							var calte;
							var namebnd;
							var dist = (json.distance)
							if (json.enbid && json.cell && json.pci) {
								var namecid = "LAC/CID/eNB ID-Cell/PCI";
								var lactac = json.lac + " / " + json.cid + " / " + json.enbid + "-" + json.cell +" / " +json.pci;
							} else if (json.enbid && json.cell) { 
								var namecid = "LAC/CID/eNB ID-Cell";
								var lactac = json.lac + " / " + json.cid + " / " + json.enbid + "-" + json.cell;
							} else if (json.enbid) {
								var namecid = "LAC/CID/eNB ID";
								var lactac = json.lac + " / " + json.cid + " / " + json.enbid;
							} else {
								var namecid = "LAC/CID";
								var lactac = json.lac + " / " + json.cid;
							}
							var carrier;
							var bcc;
							var bca = "";
							var scc;
							var cid;
							var arfcn = json.arfcn + " (" + dlfreq + " / " + ulfreq + " MHz)";
							// name channels and signal/noise  
							if (netmode == "LTE") {
								var calte = (json.lteca)
								var carrier;
								var scc;
								var bwca = json.bwca;
								distance = " ~"+ dist +" km";
								if (calte > 0) {
									carrier = "+";
									scc = json.scc;
									bw = bwca;
									bca = " / " + bw + " MHz";
									bcc = " B" + band + "" + scc;
								} else {
									scc = "";
									bcc = " B" + band;
									if (bw) {
										bca = " / " + bw + " MHz";
									} else{
										bca = ""
									}
								}
								var namech = "EARFCN";
								var namesnr = "SINR";
								//var lactac = data.lac + " (" + data.lac_num + ") / " + data.enbid;
							} else if (netmode == 
								"3G" || netmode == 
								"UMTS" || netmode == 
								"HSPA" || netmode == 
								"HSUPA" || netmode == 
								"HSDPA" || netmode == 
								"HSPA+" || netmode == 
								"WCDMA" || netmode == 
								"DC-HSPA+" || netmode == 
								"HSDPA+HSUPA" || netmode ==
								"HSDPA,HSUPA") {
								var namech = "UARFCN";
								var namesnr = "ECIO";
								var namecid = "LAC/CID";
								var lactac = json.lac + " / " + json.cid;
								var bcc = " " + band;
							} else {
								var namech = "ARFCN";
								var namesnr = "SINR/ECIO";
								var namecid = "LAC/CID";
								var lactac = json.lac + " / " + json.cid;
								var bcc = " " + band;
							}
							if (bw) { 
								namebnd = _('Network/Band/Bandwidth');
							} else {
								namebnd = _('Network/Band');
							}

							// json.signal --> always undefined, may be unused?
							return { "signal" : json.signal,
								 	 "mode" : json.mode,
								 	 "carrier" : carrier,
								 	 "bcc" : bcc, 
								 	 "bca" : bca, 
								 	 "rg" : rg,
								 	 "dist" : dist,
								 	 "cops" : json.cops,
								 	 "color" : json.csq_col,
								 	 "reg" : reg,
								 	 "icon" : icon,
								 	 "p" : p,
								 	 "distance" : distance
									};
			})
	},
	render: function(data) {
		var index = uci.sections('modeminfo');
		var signal = document.createElement('div');
		if (data.rg == 1 || data.rg == 6 || data.rg == 9) {
			if (data.dist == "--" || data.dist == "" || data.dist == "0.00") {
				signal.innerHTML = String.format(data.cops +'<img style="padding-left: 10px;" src="%s"/>'  + " " +  '<span class="ifacebadge"><p style="color:'+ data.color +'"><b>%d%%</b></p></span>', data.icon, data.p);
			} else {
				signal.innerHTML = String.format(data.cops +'<img style="padding-left: 10px;" src="%s"/>'  + " " +  '<span class="ifacebadge"><p style="color:'+ data.color +'"><b>%d%%</b></p></span>' + data.distance, data.icon, data.p);
			}
		} else if (data.rg == 5 || data.rg == 7 || data.rg == 10) {
			if (data.dist == "--" || data.dist == "" || data.dist == "0.00") {
				signal.innerHTML = String.format(data.cops + "(" + data.reg + ')<img style="padding-left: 10px;" src="%s"/>'  + " " +  '<span class="ifacebadge"><p style="color:'+ data.color +'"><b>%d%%</b></p></span>', data.icon, data.p);
			} else {
				signal.innerHTML = String.format(data.cops + "(" + data.reg + ')<img style="padding-left: 10px;" src="%s"/>'  + " " +  '<span class="ifacebadge"><p style="color:'+ data.color +'"><b>%d%%</b></p></span>' + data.distance, data.icon, data.p);
			}
		} else {
			signal.innerHTML = String.format(data.reg);
		}

		var mode = data.mode != '' ? String.format(data.mode + "" + data.carrier + " /"+ data.bcc +""+ data.bca) : "--";

		var status =
				E('div', { 'class': 'cbi-section' }, [
					E('table', { 'class': 'table' }, [
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left', 'width': '33%' }, [ _('Operator')]),
							E('td', { 'class': 'td left', 'id': 'status' }, [ signal ]),
						]),
						E('tr', { 'class': 'tr' }, [
							E('td', { 'class': 'td left', 'width': '33%', 'id': 'namebnd' }, [ _('Network')]),
							E('td', { 'class': 'td left', 'id': 'mode' }, [ mode ]),
						])
					])
				]);
		if (index[0].index == "1") {
			return status;
		}
	}
});
