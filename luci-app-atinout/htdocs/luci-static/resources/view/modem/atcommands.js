'use strict';
'require dom';
'require form';
'require fs';
'require ui';
'require uci';
'require view';

/*
	Copyright 2022-2023 Rafał Wabik - IceG - From eko.one.pl forum

	Modified for atinout by Konstantine Shevlakov <shevlakov@132lan.ru> 2023

	Licensed to the GNU General Public License v3.0.
*/

return view.extend({
	handleCommand: function(exec, args) {
		var buttons = document.querySelectorAll('.cbi-button');

		for (var i = 0; i < buttons.length; i++)
			buttons[i].setAttribute('disabled', 'true');

		return fs.exec(exec, args).then(function(res) {
			var out = document.querySelector('.atcommand-output');
			out.style.display = '';

			res.stdout = res.stdout?.replace(/(?=\n)$|\s*|\s*$|\n\n+/gm, "") || '';
			res.stderr = res.stderr?.replace(/(?=\n)$|\s*|\s*$|\n\n+/gm, "") || '';

			dom.content(out, [ res.stdout || '', res.stderr || '' ]);
			
		}).catch(function(err) {
			ui.addNotification(null, E('p', [ err ]))
		}).finally(function() {
			for (var i = 0; i < buttons.length; i++)
			buttons[i].removeAttribute('disabled');

		});
	},

	handleGo: function(ev) {

		var port, atcmd = document.getElementById('cmdvalue').value;
		var sections = uci.sections('atinout');
		var port = sections[0].atc_port;

		if ( atcmd.length < 2 )
		{
			ui.addNotification(null, E('p', _('Please specify the AT command to send')), 'info');
			return false;
		}
		else {

		if ( !port )
			{
			ui.addNotification(null, E('p', _('Please set the port for communication with the modem')), 'info');
			return false;
			}
			else {
			return this.handleCommand('luci-app-atinout', [ atcmd,  port ]);
			}
		}

		if ( !port )
		{
			ui.addNotification(null, E('p', _('Please set the port for communication with the modem')), 'info');
			return false;
		}

	},

	handleClear: function(ev) {
		var out = document.querySelector('.atcommand-output');
		out.style.display = 'none';

		var ov = document.getElementById('cmdvalue');
		ov.value = '';

		document.getElementById('cmdvalue').focus();
	},

	handleCopy: function(ev) {
		var out = document.querySelector('.atcommand-output');
		out.style.display = 'none';

		var ov = document.getElementById('cmdvalue');
		ov.value = '';
		var x = document.getElementById('tk').value;
		ov.value = x;
	},

	load: function() {
		return Promise.all([
			L.resolveDefault(fs.read_direct('/etc/atcommands.user'), null),
			uci.load('atinout')
		]);
	},

	render: function (loadResults) {
	
	var info = _('User interface for handling AT commands using atinout utility.');

		return E('div', { 'class': 'cbi-map', 'id': 'map' }, [
				E('h2', {}, [ _('AT Commands') ]),
				E('div', { 'class': 'cbi-map-descr'}, info),
				E('hr'),
				E('div', { 'class': 'cbi-section' }, [
					E('div', { 'class': 'cbi-section-node' }, [
						E('div', { 'class': 'cbi-value' }, [
							E('label', { 'class': 'cbi-value-title' }, [ _('User AT commands') ]),
							E('div', { 'class': 'cbi-value-field' }, [
								E('select', { 'class': 'cbi-input-select', 'id': 'tk', 'style': 'margin:5px 0; width:100%;', 'change': ui.createHandlerFn(this, 'handleCopy')},
									(loadResults[0] || "").trim().split("\n").map(function(cmd) {
										var fields = cmd.split(/;/);
										var name = fields[0];
										var code = fields[1];
									return E('option', { 'value': code }, name ) })
								)
							]) 
						]),
						E('div', { 'class': 'cbi-value' }, [
							E('label', { 'class': 'cbi-value-title' }, [ _('Command to send') ]),
							E('div', { 'class': 'cbi-value-field' }, [
							E('input', {
								'style': 'margin:5px 0; width:100%;',
								'type': 'text',
								'id': 'cmdvalue',
								'data-tooltip': _('Press [Enter] to send the command, press [Delete] to delete the command'),
								'keydown': function(ev) {
									 if (ev.keyCode === 13) 
										{
										var execBtn = document.getElementById('execute');
											if (execBtn)
												execBtn.click();
										}
									 if (ev.keyCode === 46)  
										{
										var del = document.getElementById('cmdvalue');
											if (del)
												var ov = document.getElementById('cmdvalue');
												ov.value = '';
												document.getElementById('cmdvalue').focus();
										}
								}																							
								}),
							])
						]),

					])
				]),
				E('hr'),
				E('div', { 'class': 'right' }, [
					E('button', {
						'class': 'cbi-button cbi-button-remove',
						'id': 'clr',
						'click': ui.createHandlerFn(this, 'handleClear')
					}, [ _('Clear form') ]),
					'\xa0\xa0\xa0',
					E('button', {
						'class': 'cbi-button cbi-button-action important',
						'id': 'execute',
						'click': ui.createHandlerFn(this, 'handleGo')
					}, [ _('Send command') ]),
				]),
				E('p', _('Reply')),
				E('pre', { 'class': 'atcommand-output', 'id': 'preout', 'style': 'display:none; border: 1px solid var(--border-color-medium); border-radius: 5px; font-family: monospace' }),

			]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
})
