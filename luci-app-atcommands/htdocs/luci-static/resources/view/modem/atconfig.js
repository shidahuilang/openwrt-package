'use strict';
'require form';
'require fs';
'require view';
'require uci';
'require ui';
'require tools.widgets as widgets'

/*
	Copyright 2022-2024 Rafał Wabik - IceG - From eko.one.pl forum
	
	Licensed to the GNU General Public License v3.0.
*/


return view.extend({
	load: function() {
		return fs.list('/dev').then(function(devs) {
			return devs.filter(function(dev) {
				return dev.name.match(/^ttyUSB/) || dev.name.match(/^cdc-wdm/) || dev.name.match(/^ttyACM/) || dev.name.match(/^mhi_/) || dev.name.match(/^wwan/);
			});
		});
	},

	render: function(devs) {
		var m, s, o;
		m = new form.Map('atcommands', _('Configuration sms-tool'), _('Configuration panel for sms-tool and gui application.'));

		s = m.section(form.TypedSection, 'atcommands', '', _(''));
		s.anonymous = true;

		o = s.option(form.Value, 'set_port', _('Port for communication with the modem'), 
			_("Select one of the available ttyUSBX ports."));
		devs.sort((a, b) => a.name > b.name);
		devs.forEach(dev => o.value('/dev/' + dev.name));
		
		o.placeholder = _('Please select a port');
		o.rmempty = false;

		o = s.option(form.TextValue, '_tmpl', _('User AT commands'),
			_("Each line must have the following format: 'At command description;AT command'. For user convenience, the file is saved to the location <code>/etc/modem/atcommands.user</code>."));
		o.rows = 20;
		o.cfgvalue = function(section_id) {
			return fs.trimmed('/etc/modem/atcommands.user');
		};
		o.write = function(section_id, formvalue) {
			return fs.write('/etc/modem/atcommands.user', formvalue.trim().replace(/\r\n/g, '\n') + '\n');
		};

		return m.render();
	}
});
