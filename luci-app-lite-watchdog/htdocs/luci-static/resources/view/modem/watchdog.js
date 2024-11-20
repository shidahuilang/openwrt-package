'use strict';
'require form';
'require fs';
'require view';
'require ui';
'require uci';
'require poll';
'require dom';
'require tools.widgets as widgets';

/*
	Copyright 2022-2024 Rafał Wabik - IceG - From eko.one.pl forum

 	MIT License
*/

return view.extend({
	formdata: { watchdog: {} },

	load: function() {
		return L.resolveDefault(fs.exec_direct('/usr/bin/lite-watchdog-data.sh', [ 'json' ]));
		uci.load('watchdog')
	},

	render: function(data) {
		var m, s, o;

		if (data != null){
		try {

		var json = JSON.parse(data);

		if (!("error" in json)) {

		var testtime = json.testtime;
		var min = json.min;
		var avg = json.avg;
		var max = json.max;

		if (min != '') {
			if (!min.includes('ms')) { 	
			min = min + " ms";
			}
			if (!avg.includes('ms')) { 	
			avg = avg + " ms";
			}
			if (!max.includes('ms')) { 	
			max = max + " ms";
			}
		}

		var onoff = json.enable;
		var dest = json.dest;
		var delay = parseInt(json.delay)/60;
		var period = json.period;
		var count = json.count;
		var action = json.action;
		
		pollData: poll.add(function() {
			return L.resolveDefault(fs.exec_direct('/usr/bin/lite-watchdog-data.sh', [ 'json' ]))
			.then(function(res) {
				var json = JSON.parse(res);

				if ( json != null ) { 

				var view = document.getElementById("testtime");
				var view2 = document.getElementById("min");
				var view3 = document.getElementById("avg");
				var view4 = document.getElementById("max");

				var min = json.min.toString();

				var ttime = json.testtime.toString();
				var countz = json.now_count.toString();
				if (countz != '-1') {
				var renderHTML = "";
				renderHTML = ttime + ' (' + _('failed') + ' ' + countz + ' ' + _('out of') + ' ' + count + ')';
				view.innerHTML  = '';
  				view.innerHTML  = renderHTML.trim();
				}

				if (min == '') {
				view2.textContent = '-';
				view3.textContent = '-';
				view4.textContent = '-';
				}
				else {
				var ttime = json.testtime.toString();
				var countz = json.now_count.toString();
				var testz = json.now_count.toString();
				var renderHTML = "";
				renderHTML = ttime + ' (' + _('failed') + ' ' + countz + ' ' + _('out of') + ' ' + count + ')';
				view.innerHTML  = '';
  				view.innerHTML  = renderHTML.trim();

				var renderHTML2 = "";
					if (!min.includes('ms')) { 	
					min = min + " ms";
					}
				renderHTML2 = min;
				view2.innerHTML  = '';
  				view2.innerHTML  = renderHTML2.trim();

				var renderHTML3 = "";
				var avg = json.avg.toString();
					if (!avg.includes('ms')) { 	
					avg = avg + " ms";
					}
				renderHTML3 = avg;
				view3.innerHTML  = '';
  				view3.innerHTML  = renderHTML3.trim();

				var max = json.max.toString();
				var renderHTML4 = "";
					if (!max.includes('ms')) { 	
					max = max + " ms";
					}
				renderHTML4 = max;
				view4.innerHTML  = '';
  				view4.innerHTML  = renderHTML4.trim();

				}

				}
			});
		});
		}		
			} catch (err) {
  				console.log('Error: ', err.message);
			}
		}
		
		var info = _('Configuration of the connection monitor, which is a conversion of the monitor known from the easyconfig package. More information on the %seko.one.pl forum%s.').format('<a href="https://eko.one.pl/?p=easyconfig" target="_blank">', '</a>');

		m = new form.JSONMap(this.formdata, _('Connection monitor settings'), info);

		s = m.section(form.TypedSection, 'watchdog', '', _(''));
		s.anonymous = true;

		s.render = L.bind(function(view, section_id) {
			return E('div', { 'class': 'cbi-section' }, [
				E('h3', _('Information')),
					E('table', { 'class': 'table' }, [
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('Last check')]),
						E('td', { 'class': 'td left', 'id': 'testtime' }, [ testtime || '-' ]),
					]),

						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('minimum')]),
						E('td', { 'class': 'td left', 'id': 'min' }, [ min || '-' ]),
					]),

						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('average')]),
						E('td', { 'class': 'td left', 'id': 'avg' }, [ avg || '-' ]),
					]),
						E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, [ _('maximum')]),
						E('td', { 'class': 'td left', 'id': 'max' }, [ max || '-' ]),
					]),
				])
			]);
		}, o, this);

		s = m.section(form.TypedSection, 'watchdog', _(''));
		s.anonymous = true;
		s.addremove = false;

		if(!("error" in json)) {
		s.tab('basic', _('Basic settings'));

		o = s.taboption('basic', form.Flag, 'enabled',	_('Enabled'),
		_('Enable a connection monitor.')
		);
		o.rmempty = false;
		o.default = onoff;

		o = s.taboption('basic', form.Value, 'delay', _('System startup delay'),
		_('[1 - 59] minute(s)')
		);
		o.default = delay || "3";
		o.rmempty = false;
		o.validate = function(section_id, value) {

			if (value.match(/^[0-9]+(?:\.[0-9]+)?$/) && +value >= 1 && +value < 60)
				return true;

			return _('Expect a decimal value between one and fifty-nine');
		};
		o.datatype = 'range(1, 59)';

		o = s.taboption('basic', form.Value, 'dest', _('Address or name'),
		_('')
		);
		o.default = dest || "google.com";
		o.rmempty = false;

		o = s.taboption('basic', form.Value, 'period', _('Verification period'),
		_('[1 - 59] minute(s)')
		);
		o.default = period || "1";
		o.rmempty = false;
		o.validate = function(section_id, value) {

			if (value.match(/^[0-9]+(?:\.[0-9]+)?$/) && +value >= 1 && +value < 60)
				return true;

			return _('Expect a decimal value between one and fifty-nine');
		};
		o.datatype = 'range(1, 59)';

		o = s.taboption('basic', form.Value, 'period_count', _('Number of failed checks'),
		_('[1 - 59]')
		);
		o.default = count || "10";
		o.rmempty = false;
		o.validate = function(section_id, value) {

			if (value.match(/^[0-9]+(?:\.[0-9]+)?$/) && +value >= 1 && +value < 60)
				return true;

			return _('Expect a decimal value between one and fifty-nine');
		};
		o.datatype = 'range(1, 59)';

		o = s.taboption('basic', form.ListValue, 'action', _('Action'));
		o.value('wan', _('Connection restart'));
		o.value('reboot', _('Reboot')); 
		o.default = action || "wan";

		}

		return m.render();
	},

	handleWATCHDOGSETup: function(ev) {
		var map = document.querySelector('#maincontent .cbi-map'),
		    data = this.formdata;

		return dom.callClassMethod(map, 'save').then(function() {
			var args = [];
			args.push(data.watchdog.enabled);
			var ax = args.toString();

			if ( ax == "1" ) {
			ui.addNotification(null, E('p', _('Changes have been saved. Connection Monitor has started.') ), 'info');
			}
			else {
			ui.addNotification(null, E('p', _('Changes have been saved. Connection Monitor is not running.') ), 'info');
			}

			var args2 = [];
			args2.push(data.watchdog.delay);
			var ax2 = parseInt(args2)*60;

			var args3 = [];
			args3.push(data.watchdog.dest);
			var ax3 = args3.toString();

			var args4 = [];
			args4.push(data.watchdog.period);
			var ax4 = args4.toString();

			var args5 = [];
			args5.push(data.watchdog.period_count);
			var ax5 = args5.toString();

			var args6 = [];
			args6.push(data.watchdog.action);
			var ax6 = args6.toString();

			return uci.load('watchdog').then(function() {
				uci.set('watchdog', '@watchdog[0]', 'enabled', ax.toString());
				uci.set('watchdog', '@watchdog[0]', 'delay', ax2.toString());
				uci.set('watchdog', '@watchdog[0]', 'dest', ax3.toString());
				uci.set('watchdog', '@watchdog[0]', 'period', ax4.toString());
				uci.set('watchdog', '@watchdog[0]', 'period_count', ax5.toString());
				uci.set('watchdog', '@watchdog[0]', 'action', ax6.toString());
				uci.save();
				uci.apply();
			fs.exec_direct('/sbin/watchdog2cron.sh');

			if ( ax == "1" ) {
				fs.exec('sleep 2');
				fs.exec_direct('/sbin/refresh2cron.sh');
			}
				
    			});
		});
	},

	addFooter: function() {
		return E('div', { 'class': 'cbi-page-actions' }, [
			E('button', {
				'class': 'cbi-button cbi-button-save',
				'click': L.ui.createHandlerFn(this, 'handleWATCHDOGSETup')
			}, [ _('Save') ])
		]);
	}

});

