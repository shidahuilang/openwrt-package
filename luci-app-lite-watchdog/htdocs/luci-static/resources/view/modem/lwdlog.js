'use strict';
'require view';
'require fs';
'require ui';
'require uci';


/*
	Copyright 2023-2024 Rafał Wabik - IceG - From eko.one.pl forum
	
	MIT License

	Tab is a modification of the package https://github.com/gSpotx2f/luci-app-syslog 
*/


return L.view.extend({
	tailDefault: 20,

	parseLogData: function(logdata) {
		/* Log file translation */
		logdata = logdata.replaceAll('Failed', _('Failed'));
		logdata = logdata.replaceAll('out of', _('out of'));
		logdata = logdata.replaceAll('Status', _('Status'));
		logdata = logdata.replaceAll('OFFLINE', _('OFFLINE'));
		logdata = logdata.replaceAll('ONLINE', _('ONLINE'));
		logdata = logdata.replaceAll('Action', _('Action'));
		logdata = logdata.replaceAll('Restarting interface', _('Restarting interface'));
		logdata = logdata.replaceAll('At command was sent to modem', _('At command was sent to modem'));
		logdata = logdata.replaceAll('Reboot', _('Reboot'));

		logdata = logdata.replaceAll('January', _('January'));
		logdata = logdata.replaceAll('February', _('February'));
		logdata = logdata.replaceAll('March', _('March'));
		logdata = logdata.replaceAll('April', _('April'));
		logdata = logdata.replaceAll('May', _('May'));
		logdata = logdata.replaceAll('June', _('June'));
		logdata = logdata.replaceAll('July', _('July'));
		logdata = logdata.replaceAll('August', _('August'));
		logdata = logdata.replaceAll('September', _('September'));
		logdata = logdata.replaceAll('October', _('October'));
		logdata = logdata.replaceAll('November', _('November'));
		logdata = logdata.replaceAll('December', _('December'));

		logdata = logdata.replaceAll('Monday', _('Monday'));
		logdata = logdata.replaceAll('Tuesday', _('Tuesday'));
		logdata = logdata.replaceAll('Wednesday', _('Wednesday'));
		logdata = logdata.replaceAll('Thursday', _('Thursday'));
		logdata = logdata.replaceAll('Friday', _('Friday'));
		logdata = logdata.replaceAll('Saturday', _('Saturday'));
		logdata = logdata.replaceAll('Sunday', _('Sunday'));
		/* Log file translation */
		return logdata.trim().split(/\n/).map(line => line.replace(/^<\d+>/, ''));
	},

	setLogTail: function(cArr) {
		let tailNumVal = document.getElementById('tailValue').value;
		if(tailNumVal && tailNumVal > 0 && cArr) {
			return cArr.slice(-tailNumVal);
		};
		return cArr;
	},

	setLogFilter: function(cArr) {
		let fPattern = document.getElementById('logFilter').value;		

		if(!fPattern) {
			return cArr;
		};
		let fArr = [];
		try {
			fArr = cArr.filter(s => new RegExp(fPattern, 'iu').test(s));
		} catch(err) {
			if(err.name === 'SyntaxError') {
				ui.addNotification(null,
					E('p', {}, _('Wrong regular expression') + ': ' + err.message));
				return cArr;
			} else {
				throw err;
			};
		};
		if(fArr.length === 0) {
			fArr.push(_('No matches...'));
		};
		return fArr;
	},

	handleClear: function(ev) {
		if (confirm(_('Clear connection monitor log?')))
			{
				var ov = document.getElementById('syslog');
				ov.value = '';
				return fs.write('/etc/modem/log.txt', '');
			}
	},

	handleChangeDetail: function(ev) {
		var x = document.getElementById('log_detail').value;

			return uci.load('watchdog').then(function() {
				uci.set('watchdog', '@watchdog[0]', 'log', x.toString());
				uci.save();
				uci.apply();
			});

	},

	handleDownload: function(ev) {
		return L.resolveDefault(fs.read_direct('/etc/modem/log.txt'), null).then(function (res) {
				if (res) {
					var link = E('a', {
						'download': 'log.txt',
						'href': URL.createObjectURL(
							new Blob([ res ], { type: 'text/plain' })),
					});
					link.click();
					URL.revokeObjectURL(link.href);
				}
			}).catch(() => {
				ui.addNotification(null, E('p', {}, _('Download error') + ': ' + err.message));
		});

	},

	load: function() {
		return fs.read_direct('/etc/modem/log.txt').catch(err => {
			ui.addNotification(null, E('p', {}, _('Unable to load log data:') + ' ' + err.message));
			return '';
		});
	},

	render: function(logdata) {
		let navBtnsTop = '1px';
		
		/* Log file translation */
		logdata = logdata.replaceAll('Failed', _('Failed'));
		logdata = logdata.replaceAll('out of', _('out of'));
		logdata = logdata.replaceAll('Status', _('Status'));
		logdata = logdata.replaceAll('OFFLINE', _('OFFLINE'));
		logdata = logdata.replaceAll('ONLINE', _('ONLINE'));
		logdata = logdata.replaceAll('Action', _('Action'));
		logdata = logdata.replaceAll('Restarting interface', _('Restarting interface'));
		logdata = logdata.replaceAll('At command was sent to modem', _('At command was sent to modem'));
		logdata = logdata.replaceAll('Reboot', _('Reboot'));

		logdata = logdata.replaceAll('January', _('January'));
		logdata = logdata.replaceAll('February', _('February'));
		logdata = logdata.replaceAll('March', _('March'));
		logdata = logdata.replaceAll('April', _('April'));
		logdata = logdata.replaceAll('May', _('May'));
		logdata = logdata.replaceAll('June', _('June'));
		logdata = logdata.replaceAll('July', _('July'));
		logdata = logdata.replaceAll('August', _('August'));
		logdata = logdata.replaceAll('September', _('September'));
		logdata = logdata.replaceAll('October', _('October'));
		logdata = logdata.replaceAll('November', _('November'));
		logdata = logdata.replaceAll('December', _('December'));

		logdata = logdata.replaceAll('Monday', _('Monday'));
		logdata = logdata.replaceAll('Tuesday', _('Tuesday'));
		logdata = logdata.replaceAll('Wednesday', _('Wednesday'));
		logdata = logdata.replaceAll('Thursday', _('Thursday'));
		logdata = logdata.replaceAll('Friday', _('Friday'));
		logdata = logdata.replaceAll('Saturday', _('Saturday'));
		logdata = logdata.replaceAll('Sunday', _('Sunday'));
		/* Log file translation */
		
		let loglines = this.parseLogData(logdata);

		uci.load('watchdog').then(function() {
		var logsettings = (uci.get('watchdog', '@watchdog[0]', 'log'));

			switch (logsettings) {
  				case 'all':
    						document.getElementById('log_detail').value = 'all';
    						break;
  				case 'offline':
    						document.getElementById('log_detail').value = 'offline';
    						break;
  				default:
				}

		});

		 let logTextarea = E('textarea', {
			'id': 'syslog',
			'class': 'cbi-input-textarea',
			'style': 'width: 100%; resize: vertical; height:400px; max-height:800px; min-height:400px; min-width:100%; padding: 0 0 0 45px; font-size:12px; font-family: monospace',
			'readonly': 'readonly',
			'wrap': 'off',
			'rows': this.tailDefault,
			'spellcheck': 'false',
		}, [ loglines.slice(-this.tailDefault).join('\n') ]);

		let tailValue = E('input', {
			'id': 'tailValue',
			'name': 'tailValue',
			'type': 'text',
			'form': 'logForm',
			'class': 'cbi-input-text',
			'style': 'width:4em !important; min-width:4em !important; margin-bottom:0.3em !important',
			'maxlength': 5,
		});
		tailValue.value = this.tailDefault;
		ui.addValidator(tailValue, 'uinteger', true);

		let logFilter = E('input', {
			'id': 'logFilter',
			'name': 'logFilter',
			'type': 'text',
			'form': 'logForm',
			'class': 'cbi-input-text',
			'style': 'min-width:16em !important; margin-right:1em !important; margin-bottom:0.3em !important',
			'placeholder': _('Entries filter'),
			'data-tooltip': _('Filter entries using regexp, press [Delete] to delete all text'),
			'keydown': function(ev) {
					if (ev.keyCode === 46)  
					{
					var del = document.getElementById('logFilter');
						if (del)
							var ov = document.getElementById('logFilter');
							ov.value = '';
							document.getElementById('logFilter').focus();
						}
					},
		});

		let logFormSubmitBtn = E('input', {
			'type': 'submit',
			'form': 'logForm',
			'class': 'cbi-button cbi-button-add',
			'style': 'margin-right:1em !important; margin-bottom:0.3em !important;',
			'value': _('Refresh'),
			'click': ev => ev.target.blur(),
		});

		return E([
			E('h2', { 'id': 'logTitle', 'class': 'fade-in' }, _('Connection monitor activity log')),
			E('div', { 'class': 'cbi-map-descr' }, _('Connection monitor activity log, which is a conversion of the monitor known from the easyconfig package. More information on the %seko.one.pl forum%s.').format('<a href="https://eko.one.pl/?p=easyconfig" target="_blank">', '</a>')),
			E('hr'),
			E('div', { 'class': 'cbi-section-descr fade-in' }),
			E('div', { 'class': 'cbi-section fade-in' },
				E('div', { 'class': 'cbi-section-node' },
					E('div', { 'id': 'contentSyslog', 'class': 'cbi-value' }, [
						E('label', {
							'class': 'cbi-value-title',
							'for': 'tailValue',
							'style': 'margin-bottom:0.3em !important',
						}, _('Show only the last entries')),
						E('div', { 'class': 'cbi-value-field' }, [
							tailValue,
							E('input', {
								'type': 'button',
								'form': 'logForm',
								'class': 'btn cbi-button',
								'value': 'x',
								'click': ev => {
									tailValue.value = null;
									logFormSubmitBtn.click();
									ev.target.blur();
								},
								'style': 'margin-right:1em !important; margin-bottom:0.3em !important; max-width:4em !important',
							}),
							E('form', {
								'id': 'logForm',
								'name': 'logForm',
								'style': 'display:inline-block; margin-bottom:0.3em !important',
								'submit': ui.createHandlerFn(this, function(ev) {
									ev.preventDefault();
									let formElems = Array.from(document.forms.logForm.elements);
									formElems.forEach(e => e.disabled = true);
									return this.load().then(logdata => {
										let loglines = this.setLogFilter(this.setLogTail(
											this.parseLogData(logdata)));
										logTextarea.rows = (loglines.length < this.tailDefault) ? this.tailDefault : loglines.length;
										logTextarea.value = loglines.join('\n');
									}).finally(() => {
										formElems.forEach(e => e.disabled = false);
									});
								}),
							}, E('span', {}, '&#160;')),
						]),

					])
				)
			),

						E('div', { 'class': 'cbi-value' }, [
							E('label', {
								'class': 'cbi-value-title',
								'for'  : 'logFilter',
							}, _('Type of messages')),
							E('div', { 'class': 'cbi-value-field' }, [
								E('select', { 'class': 'cbi-input-select', 'id': 'log_detail', 'change': ui.createHandlerFn(this, 'handleChangeDetail') }, [
								E('option', { 'value': 'all' }, _('All actions')),
								E('option', { 'value': 'offline' }, _('Only connection problems'))
								]),
							])
						]),

						E('div', { 'class': 'cbi-value' }, [
							E('label', {
								'class': 'cbi-value-title',
								'for'  : 'logFilter',
							}, _('Message filter')),
							E('div', { 'class': 'cbi-value-field' }, logFilter),
						]),

						E('div', { 'class': 'cbi-value' }, [
							E('label', {
								'class': 'cbi-value-title',
								'for'  : 'logFormSubmitBtn',
							}, _('Refresh log')),
							E('div', { 'class': 'cbi-value-field' }, [
								logFormSubmitBtn,
							])
						]),

			E('div', { 'class': 'cbi-section fade-in' },
				E('div', { 'class': 'cbi-section-node' }, [
					E('div', { 'style': 'position:fixed' }, [
						E('button', {
							'class': 'btn',
							'style': 'position:relative; display:block; margin:0 !important; left:1px; top:'
								+ navBtnsTop,
							'click': ev => {
								document.getElementById('logTitle').scrollIntoView(true);
								ev.target.blur();
							},
						}, '\u25b2'),
						E('button', {
							'class': 'btn',
							'style': 'position:relative; display:block; margin:0 !important; margin-top:1px !important; left:1px; top:'
								+ navBtnsTop,
							'click': ev => {
								logTextarea.scrollIntoView(false);
								ev.target.blur();
							},
						}, '\u25bc'),
					]),
					logTextarea,
				])
			),
				E('div', { 'class': 'right' }, [
					E('button', {
						'class': 'cbi-button cbi-button-remove',
						'id': 'clear',
						'click': ui.createHandlerFn(this, 'handleClear')
					}, [ _('Clear log') ]),
					'\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-apply important',
						'id': 'download',
						'click': ui.createHandlerFn(this, 'handleDownload')
					}, [ _('Download log') ]),
				]),
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
});
