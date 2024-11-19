'use strict';
'require view';
'require uci';
'require form';
'require tools.widgets as widgets';

return view.extend({
//	handleSaveApply: null,
//	handleSave: null,
//	handleReset: null,

	load: function() {
		return Promise.all([
			uci.load('luci_netports')
		]);	
	},

	render: function(data) {

		var m, s, o;

		m = new form.Map('luci_netports', _('Network Interfaces Ports Status'));

		s = m.section(form.NamedSection, 'global', 'global');
		s.anonymous = true;

		o = s.option(form.Flag, 'default_additional_info', _('Display additional information in horizontal view mode by default'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Flag, 'default_h_mode', _('Use horizontal view mode by default'));
		o.default = o.enabled;
		o.rmempty = false;

		o = s.option(form.Flag, 'hv_mode_switch_button', _('Show button for manual switching between horizontal/vertical view modes'));
		o.default = o.enabled;
		o.rmempty = false;

		s = m.section(form.GridSection, 'port', _('Port List'));
		s.sortable  = true;
		s.anonymous = true;
		s.addremove = true;

		o = s.option(widgets.DeviceSelect, 'ifname', _('interface'));
		o.multiple = false;
		o.noaliases = true;
		o.nobridges = true;
		o.nocreate = true;
		o.rmempty = false;

		o = s.option(form.Value, 'name', _('Nick name'));
		o.rmempty = true;

		o = s.option(form.ListValue, 'type', _('Port type'));
		o.value('auto', _('Auto detect'));
		o.value('copper', _('RJ45') + ' ' + _('connection'));
		o.value('sfp', _('SFP') + ' ' + _('connection'));
		o.value('fixed', _('Intercircuit fixed link') + ' ' + _('connection'));
		o.value('wifi', _('Wireless') + ' ' + _('connection'));
		o.value('usb_wifi', _('USB Wireless') + ' ' + _('connection'));
		o.value('usb_rndis', _('USB RNDIS') + ' ' + _('connection'));
		o.value('usb_stick', _('USB modem') + ' ' + _('connection'));
		o.value('usb_2g', _('USB 2G modem') + ' ' + _('connection'));
		o.value('usb_3g', _('USB 3G modem') + ' ' + _('connection'));
		o.value('usb_4g', _('USB 4G modem') + ' ' + _('connection'));
		o.value('gprs', _('GPRS') + ' ' + _('connection'));
		o.value('vpn', _('VPN') + ' ' + _('connection'));
		o.value('tunnel', _('Tunnel') + ' ' + _('connection'));
		o.value('ppp', _('PPP') + ' ' + _('connection'));
		o.default = 'auto';
		o.rmempty = true;

		o = s.option(form.Flag, 'disable', _('Hidden'));
		o.default = o.disabled;
		o.editable = true;
		o.rmempty = true;

		return m.render()
	}
});
