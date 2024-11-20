'use strict';
'require view';
'require uci';
'require dom';
'require form';
'require rpc';
'require fs';
'require ui';
'require tools.widgets as widgets';

/*
	Copyright (c) 2024 Rafał Wabik - IceG - From eko.one.pl forum
	
	Licensed to the GNU General Public License v3.0.
	
	
	Transfer statistics from easyconfig available in LuCI JS. 
	Package is my simplified conversion.
	You are using a development version of package.
	
	More information on <https://eko.one.pl/?p=easyconfig>.
*/

return view.extend({
	load: function() {
		uci.load('easyconfig_transfer');
	},
	
	handleDLBackup: function(ev) {
    	var form = E('form', {
        	'method': 'post',
        	'action': '/cgi-bin/cgi-download/easyconfig_statistics.json.gz',
        	'enctype': 'application/x-www-form-urlencoded'
    		}, [
        	E('input', { 'type': 'hidden', 'name': 'sessionid', 'value': rpc.getSessionID() }),
        	E('input', { 'type': 'hidden', 'name': 'path',      'value': '/etc/modem/easyconfig_statistics.json.gz' })
    	]);

    	ev.currentTarget.parentNode.appendChild(form);

    		form.submit();
    		form.parentNode.removeChild(form);
	},

	handleRestoreGZ: function(ev) {
		return ui.uploadFile('/tmp/easyconfig_statistics.json.gz', ev.target).then(L.bind(function(btn, res) {
			return fs.exec('/bin/gzip', ['-t', '/tmp/easyconfig_statistics.json.gz']);
		}, this, ev.target)).then(L.bind(function(btn, res) {
			if(res.code != 0) {
				ui.addNotification(null, E('p', _('The uploaded backup archive is not readable')));
				return fs.remove('/tmp/easyconfig_statistics.json.gz');
			}
			ui.showModal(_('Apply backup?'), [
				E('p', _("Press Continue to restore the backup, or Cancel to abort the operation.")),
				E('div', {
					'class': 'right'
				}, [
					E('button', {
						'class': 'btn',
						'click': ui.createHandlerFn(this, function(ev) {
							return fs.remove('/tmp/easyconfig_statistics.json.gz').finally(ui.hideModal);
						})
					}, [_('Cancel')]), ' ',
					E('button', {
						'class': 'btn cbi-button-action important',
						'click': ui.createHandlerFn(this, 'handleRestoreConfirmGZ', btn)
					}, [_('Continue')])
				])
			]);
		}, this, ev.target)).catch(function(e) {
			ui.addNotification(null, E('p', e.message))
		}).finally(L.bind(function(btn, input) {}, this, ev.target));
	},

	handleRestoreConfirmGZ: function(btn, ev) {
		return fs.remove('/tmp/easyconfig_statistics.json'),
			fs.exec('/bin/gzip', ['-d', '/tmp/easyconfig_statistics.json.gz']).then(L.bind(function(btn, res) {
				if(res.code != 0) {
					ui.addNotification(null, [
						E('p', _('The restore command failed with code %d').format(res.code)),
						res.stderr ? E('pre', {}, [res.stderr]) : ''
					]);
					L.raise('Error', 'Unpack failed');
				}
				return fs.remove('/tmp/easyconfig_statistics.json.gz').finally(ui.hideModal);
			}, this, ev.target))
	},

	handleRestoreJS: function(ev) {
		return ui.uploadFile('/tmp/easyconfig_statistics.json', ev.target).then(L.bind(function(btn, res) {}, this, ev.target)).catch(function(e) {
			ui.addNotification(null, E('p', e.message))
		}).finally(L.bind(function(btn, input) {}, this, ev.target));
	},

	render: function(devs) {
		var m, s, o;
		m = new form.Map('easyconfig_transfer', _('Configuration - Transfer'), _('Configuration panel of the application calculating transfer statistics.'));

		s = m.section(form.TypedSection, 'ectransfer', _('Main Settings'), null);
		s.anonymous = true;

		o = s.option(form.Flag, 'transfer_enabled', _('Enable'), _('Enable transfer data collection. <br />Data is saved to file <code>/tmp/easyconfig_statistics.json</code>. \
				<br /><br /><b>What you should know</b> \
				<br />With flow offloading enabled, transfer data will be inconsistent with reality or may be completely unavailable.'));

		o.rmempty = false;
		o.write = function(section_id, value) {
			if(value == '1') {
				uci.set('easyconfig_transfer', 'global', 'transfer_enabled', "1");
				uci.save();
				fs.exec('sleep 2');
				fs.exec_direct('/sbin/transfer2cron.sh');
			}
			if(value == '0') {
				uci.set('easyconfig_transfer', 'global', 'transfer_enabled', "0");
				uci.save();
				fs.exec('sleep 2');
				fs.exec_direct('/sbin/transfer2cron.sh');
			}
			return form.Flag.prototype.write.apply(this, [section_id, value]);
		};

		o = s.option(widgets.NetworkSelect, 'network', _('Interface'), _('Network interface for Internet access.'));
		o.exclude = s.section;
		o.nocreate = true;
		o.rmempty = false;
		o.default = 'wan';
		//o.depends('transfer_enabled', '1');
		
		o = s.option(form.ListValue, 'dataread_period', _('Data reading period '), _('[1 - 59] minute(s)'));
		o.rmempty = false;
		for(var i = 1; i < 60; i++) {
			o.value(i, i);
		}
		o.default = '10';
		//o.depends('transfer_enabled', '1');

		o = s.option(form.ListValue, 'datarec_period', _('Data recording period'),
			 _('Select how often a compressed copy of the data will be made. <br />Archive path <code>/etc/modem/easyconfig_statistics.json.gz</code>. \
				<br /><br /><b>Important</b> \
				<br />Please remember that frequent write operations shorten the life cycle of memory.'));

		o.value('0', _('Disabled'));
		o.value('1', _('1 minute'));
		o.value('2', _('3 minutes'));
		o.value('5', _('5 minutes'));
		o.value('10', _('10 minutes'));
		o.value('15', _('15 minutes'));
		o.value('30', _('30 minutes'));
		o.value('60', _('1 hour'));
		o.value('180', _('3 hours'));
		o.value('360', _('6 hours'));
		o.value('720', _('12 hours'));
		o.value('1440', _('24 hours'));
		o.rmempty = true;
		o.default = '180';
		//o.depends('transfer_enabled', '1');

		s = m.section(form.TypedSection, 'service', _('Additional settings'), null);
		s.anonymous = true;

		s.tab('trTab', _('Traffic Settings'));

		o = s.taboption('trTab', form.ListValue, 'cycle', _('Beginning of the billing period'), _('Enter the starting day of the billing period.'));
		o.rmempty = false;
		for(var i = 1; i < 32; i++) {
			o.value(i, i);
		}

		o = s.taboption('trTab', form.ListValue, 'hidden_data', _('Hide selected data in the table'), _('Select data that will be hidden.'));
		o.value('n', _('None'));
		o.value('m', _('MAC addresses'));
		o.value('h', _('Hostnames'));
		o.value('mh', _('MAC addresses & Hostnames'));
		o.rmempty = false;

		o = s.taboption('trTab', form.Flag, 'zero_view', _('Hide MAC addresses'), _('Hide MAC addresses without transfer information.'));
		o.rmempty = false;
		o.default = '1';

		o = s.taboption('trTab', form.Flag, 'wan_view', _('Show wan in table'), _('Check this option if you want wan to be visible in the table.'));
		o.rmempty = false;

		o = s.taboption('trTab', form.DynamicList, 'host_names', _('Add a hostname'), _('Enter data as <code>MAC adress;Hostname</code>.'));
		o.rmempty = true;
		o.validate = function(section_id, value) {
			if(value === "" || value.match(/^([0-9A-F]{2}:){5}([0-9A-F]{2});.+$/)) {
				return true;
			} else {
				return _('Enter the MAC address;Hostname');
			}
		};

		o = s.taboption('trTab', form.Flag, 'warning_enabled', _('Enable data usage progress bar'), _('Show a visualization of transfer usage in the form of a progress bar.'));
		o.rmempty = true;

		o = s.taboption('trTab', form.Value, 'warning_value', _('Transfer available'), _('Enter the available transfer during the billing period.'));
		o.rmempty = true;
		o.depends('warning_enabled', '1');
		o.validate = function(section_id, value) {
			if(!isNaN(value) && value !== "" && Number.isInteger(Number(value))) {
				return true;
			}
			return _('Enter a numeric value');
		};
		o.default = '100';

		o = s.taboption('trTab', form.ListValue, 'warning_unit', _('Unit of data size'));
		o.value('m', _('MiB'));
		o.value('g', _('GiB'));
		o.value('t', _('TiB'));
		o.rmempty = true;
		o.depends('warning_enabled', '1');
		o.default = 'g';

		o = s.taboption('trTab', form.ListValue, 'warning_cycle', _('Data Count Cycle'), _('Specify the data visualization/counting interval.'));
		o.value('p', _('per period'));
		o.value('d', _('per day'));
		o.rmempty = true;
		o.depends('warning_enabled', '1');
		o.default = 'p';
		s.tab('bkTab', _('Backup Settings'));

		o = s.taboption('bkTab', form.Button, 'restore', _('Restore .json file from archive'), _('Option allows user to restore statistics from the archive.'));
		o.inputstyle = 'action important';
		o.inputtitle = _('Upload .gz archive');
		o.onclick = L.bind(this.handleRestoreGZ, this);

		o = s.taboption('bkTab', form.Button, 'restore', _('Restore .json file'), _('Option allows user to restore statistics from .json file.'));
		o.inputstyle = 'action important';
		o.inputtitle = _('Upload .json file');
		o.onclick = L.bind(this.handleRestoreJS, this);

		o = s.taboption('bkTab', form.Button, 'dl_backupgz', _('Download .gz archive'), _('Click to download .gz archive.'));
		o.inputstyle = 'action edit';
		o.inputtitle = _('Save .gz file');
		o.onclick = L.bind(this.handleDLBackup, this);

		o = s.taboption('bkTab', form.Button, 'dl_backupjs', _('Download .json file'), _('Click to download .json file.'));
		o.inputstyle = 'action edit';
		o.inputtitle = _('Save .json file');
		o.onclick = function() {
			fs.exec_direct('/usr/bin/easyconfig_statistics.sh').then(function() {
				fs.stat('/tmp/easyconfig_statistics.json').then(function() {
					L.resolveDefault(fs.read_direct('/tmp/easyconfig_statistics.json'), null).then(function(restxt) {
						if(restxt) {
							var link = E('a', {
								'download': 'easyconfig_statistics.json',
								'href': URL.createObjectURL(new Blob([restxt], {
									type: 'application/json'
								})),
							});
							link.click();
							URL.revokeObjectURL(link.href);
						} else {
							ui.addNotification(null, E('p', {}, _('Download of easyconfig_statistics.json failed. Please try again.')));
						}
					}).catch(() => {
						ui.addNotification(null, E('p', {}, _('Download error') + ': ' + err.message));
					});
				});
			}).catch(() => {
				ui.addNotification(null, E('p', {}, _('Error executing easyconfig_statistics.sh')));
			});
		};

		o = s.taboption('bkTab', form.Flag, 'enable_backup', _('Move .json file'), _('Check this option if you want to save data during a scheduled device restart.'));
		o.rmempty = false;
		o.write = function(section_id, value) {
			if(value == '1') {
				uci.set('easyconfig_transfer', 'service', 'traffic', 'enable_backup', "1");
				uci.save();
				fs.exec('sleep 2');
				fs.exec_direct('/sbin/backup2cron.sh');
			}
			if(value == '0') {
				uci.set('easyconfig_transfer', 'service', 'traffic', 'enable_backup', "0");
				uci.save();
				fs.exec('sleep 2');
				fs.exec_direct('/sbin/backup2cron.sh');
			}
			return form.Flag.prototype.write.apply(this, [section_id, value]);
		};
		//o.depends('transfer_enabled', '1');

		o = s.taboption('bkTab', form.Value, 'make_time', _('Backup at'), _("Correct time format <code>HH:MM</code>."));
		o.rmempty = true;
		//o.depends('transfer_enabled', '1');
		o.validate = function(section_id, value) {
			if(value.match(/^\d{1,2}:\d{2}$/)) {
				var parts = value.split(':');
				var hours = parseInt(parts[0]);
				var minutes = parseInt(parts[1]);
				if(hours >= 0 && hours < 24 && minutes >= 0 && minutes < 60) {
					return true;
				}
			}
			return _('Expected time is in HH:MM format');
		};
		o.default = '05:05';

		o = s.taboption('bkTab', form.Value, 'restore_time', _('Restore backup at'), _("Correct time format <code>HH:MM</code>."));
		o.rmempty = true;
		//o.depends('transfer_enabled', '1');
		o.validate = function(section_id, value) {
			if(value.match(/^\d{1,2}:\d{2}$/)) {
				var parts = value.split(':');
				var hours = parseInt(parts[0]);
				var minutes = parseInt(parts[1]);
				if(hours >= 0 && hours < 24 && minutes >= 0 && minutes < 60) {
					return true;
				}
			}
			return _('Expected time is in HH:MM format');
		};
		o.default = '05:10';
		return m.render();
	}
});
