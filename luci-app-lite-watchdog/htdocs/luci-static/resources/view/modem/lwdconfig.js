'use strict';
'require baseclass';
'require form';
'require fs';
'require uci';
'require ui';
'require view';
'require tools.widgets as widgets'

/*
	Copyright 2022-2024 Rafał Wabik - IceG - From eko.one.pl forum

 	MIT License
*/

return view.extend({
	usrScriptPath       : '/etc/lite_watchdog.user',

	load: function() {
		return fs.list('/dev').then(function(devs) {
			return devs.filter(function(dev) {
				return dev.name.match(/^ttyUSB/) || dev.name.match(/^cdc-wdm/) || dev.name.match(/^ttyACM/) || dev.name.match(/^mhi_/) || dev.name.match(/^wwan/);
			});
		});
	},
	
	fileEditDialog: baseclass.extend({
		__init__: function(file, title, description, callback, fileExists=false) {
			this.file        = file;
			this.title       = title;
			this.description = description;
			this.callback    = callback;
			this.fileExists  = fileExists;
		},

		load: function() {
			return L.resolveDefault(fs.read(this.file), '');
		},

		render: function(content) {
			ui.showModal(this.title, [
				E('div', { 'class': 'cbi-section' }, [
					E('div', { 'class': 'cbi-section-descr' }, this.description),
					E('div', { 'class': 'cbi-section' },
						E('p', {},
							E('textarea', {
								'id': 'widget.modal_content',
								'class': 'cbi-input-textarea',
								'style': 'width:100% !important',
								'rows': 10,
								'wrap': 'off',
								'spellcheck': 'false',
							},
							content)
						)
					),
				]),
				E('div', { 'class': 'right' }, [
					E('button', {
						'class': 'btn',
						'click': ui.hideModal,
					}, _('Dismiss')),
					' ',
					E('button', {
						'id': 'btn_save',
						'class': 'btn cbi-button-positive important',
						'click': ui.createHandlerFn(this, this.handleSave),
					}, _('Save')),
				]),
			]);
		},

		handleSave: function(ev) {
			let textarea = document.getElementById('widget.modal_content');
			let value = textarea.value.trim().replace(/\r\n/g, '\n') + '\n';

			return fs.write(this.file, value).then(rc => {
				textarea.value = value;
				ui.addNotification(null, E('p', _('Contents have been saved.')),
					'info');
				if(this.callback) {
					return this.callback(rc);
				};
			}).catch(e => {
				ui.addNotification(null, E('p', _('Unable to save the contents')
					+ ': %s'.format(e.message)));
			}).finally(() => {
				ui.hideModal();
			});
		},

		error: function(e) {
			if(!this.fileExists && e instanceof Error && e.name === 'NotFoundError') {
				return this.render();
			} else {
				ui.showModal(this.title, [
					E('div', { 'class': 'cbi-section' },
						E('p', {}, _('Unable to read the contents')
							+ ': %s'.format(e.message))
					),
					E('div', { 'class': 'right' },
						E('button', {
							'class': 'btn',
							'click': ui.hideModal,
						}, _('Dismiss'))
					),
				]);
			};
		},

		show: function() {
			ui.showModal(null,
				E('p', { 'class': 'spinning' }, _('Loading'))
			);
			this.load().then(content => {
				ui.hideModal();
				return this.render(content);
			}).catch(e => {
				ui.hideModal();
				return this.error(e);
			})
		},
	}),

	render: function(devs) {
	
		let usrScriptEditDialog = new this.fileEditDialog(
			this.usrScriptPath,
			_('User script'),
			_("User-defined commands."),
		);
	
		let m, s, o;
		m = new form.Map('watchdog', _('Configuration lite-watchdog'), _('Configuration panel for lite-watchdog and gui application.'));

		s = m.section(form.TypedSection, 'watchdog', '', _(''));
		s.anonymous = true;

/*		Old config
		o = s.option(widgets.DeviceSelect, 'iface', _('Interface'),
		_('Network interface for Internet access.')
		);
		o.noaliases  = false;
		o.default = 'wan';
*/
		
		o = s.option(widgets.NetworkSelect, 'iface', _('Interface'),
		_('Network interface for Internet access.')
		);
		o.exclude = s.section;
		o.nocreate = true;
		o.rmempty = false;
		o.default = 'wan';
		
		o = s.option(form.Button,
			'_usr_script_btn', _('Edit user script'),
			_('Before executing the action, system calls a script in which user can place his own commands.')
		);
		o.onclick    = () => usrScriptEditDialog.show();
		o.inputtitle = _('Edit');
		o.inputstyle = 'edit btn';

		o = s.option(form.Flag, 'modemrestart', _('Modem restart'),
		_('Perform a modem restart before resuming the connection.')
		);
		o.rmempty = false;

		o = s.option(form.Value, 'set_port', _('Port for communication with the modem'), 
			_("Select one of the available ttyUSBX ports."));
		devs.sort((a, b) => a.name > b.name);
		devs.forEach(dev => o.value('/dev/' + dev.name));
		o.placeholder = _('Please select a port');
		o.rmempty = false;
		o.depends("modemrestart", "1");

		o = s.option(form.Value, 'restartcmd', _('Restart modem with AT command'),
		_('AT command to restart the modem.')
		);
		o.default = 'at+cfun=1,1';
		o.rmempty = false;
		o.depends("modemrestart", "1");

		o = s.option(form.Flag, 'ledstatus', _('LED settings'),
		_('The LED shows the internet connection status.')
		);
		o.rmempty = false;

		o = s.option(form.ListValue, 'led',_('<abbr title="Light Emitting Diode">LED</abbr> Name'),
			_("Select the status LED."));
		o.load = function(section_id) {
			return L.resolveDefault(fs.list('/sys/class/leds'), []).then(L.bind(function(leds) {
				if(leds.length > 0) {
				leds.sort((a, b) => a.name > b.name);
				leds.forEach(e => o.value(e.name));
				}
				return this.super('load', [section_id]);
			}, this));
		};
		o.rmempty = false;
		o.depends("ledstatus", "1");

		return m.render();
	}
});
