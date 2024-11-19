'use strict';
'require view';
'require dom';
'require fs';
'require uci';
'require ui';
'require form';
'require tools.widgets as widgets';

return view.extend({
//	handleSaveApply: null,
//	handleSave: null,
//	handleReset: null,

//	callInitAction: rpc.declare({
//		object: 'luci',
//		method: 'setInitAction',
//		params: [ 'name', 'action' ],
//		expect: { result: false }
//	}),

	load: function() {
	return Promise.all([
		L.resolveDefault(fs.stat('/usr/bin/rgmac'), {}),
		uci.load('network'),
		uci.load('change-mac'),
	]);
	},

	handleCommand: function(exec, args) {
		var buttons = document.querySelectorAll('.diag-action > .cbi-button');

		for (var i = 0; i < buttons.length; i++)
			buttons[i].setAttribute('disabled', 'true');

		return fs.exec(exec, args).then(function(res) {
			var out = document.querySelector('.command-output');
				out.style.display = '';

			dom.content(out, [ res.stdout || '', res.stderr || '' ]);
		}).catch(function(err) {
			ui.addNotification(null, E('p', [ err ]))
		}).finally(function() {
			for (var i = 0; i < buttons.length; i++)
				buttons[i].removeAttribute('disabled');
		});
	},

	handleQueryOUI: function(ev, cmd) {
		var addr = ev.currentTarget.parentNode.previousSibling.value;

		return this.handleCommand('rgmac', [ '-e', addr ]);
	},

	handleQueryVendor: function(ev, cmd) {

		return this.handleCommand('rgmac', [ '-lrouter' ]);
	},

//	handleAction: function(name, action, ev) {
//		return this.callInitAction(name, action).then(function(success) {
//			if (success != true)
//				throw _('Command failed');
//
//			return true;
//		}).catch(function(e) {
//			ui.addNotification(null, E('p', _('Failed to execute "/etc/init.d/%s %s" action: %s').format(name, action, e)));
//		});
//	},

	handleAction: function(m, action, ev) {
		m.save();
		uci.save();
		uci.apply();
		uci.unload('change-mac');
		uci.load('change-mac');

		return fs.exec('/etc/init.d/change-mac', [action])
			.then(L.bind(uci.unload, uci, 'change-mac'))
			.then(L.bind(m.render, m))
			.catch(function(e) { ui.addNotification(null, E('p', e.message)) });
	},

	render: function(res) {
		var has_rgmac = res[0].path,
			oui_be_queried = uci.get('change-mac', '@change-mac[0]', 'mac_type_specific') || '74:D0:2B';

		var m, s, o;

		m = new form.Map('change-mac', _('MAC address randomizer'),
			_('Assign a random MAC address to the designated interface on every time boot'));

		s = m.section(form.TypedSection, 'change-mac');
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('Enable MAC randomization'));
		o.rmempty = false;

		o = s.option(widgets.DeviceSelect, 'interface', _('Enabled interfaces'));
		o.multiple = true;
		o.noaliases = true;
		o.nobridges = true;
		o.nocreate = true;

		o = s.option(form.ListValue, 'random_mode', _('Multi-interface MAC random mode'));
		o.value('disorderly', _('Disorderly'));
		o.value('sequence', _('Sequence'));
		o.default = 'disorderly';
		o.rmempty = false;

		o = s.option(form.ListValue, 'mac_type', _('MAC address type'),
			_("Use command 'rgmac --help' to get more information"));
		o.value('locally', _('Locally administered address'));
		o.value('specific', _('Specify OUI'));
		o.value('vendor', _('Vendor name'));
		o.default = 'locally';
		o.rmempty = false;

		o = s.option(form.Value, 'mac_type_specific', _('Specify OUI'));
		o.placeholder = 'OUI    e.g. 74:D0:2B';
		//o.depends('mac_type', 'specific');
		o.rmempty = false;

		o = s.option(form.Value, 'mac_type_vendor', _('Vendor name'),
			_("Use command 'rgmac -lrouter' to get valid vendor name"));
		o.placeholder = 'VendorType:NameID    e.g. router:Asus';
		//o.depends('mac_type', 'vendor');
		o.rmempty = false;

		o = s.option(form.Button, '_change_now', _('Change MAC now'));
		o.inputtitle = _('Change now');
		o.inputstyle = 'apply';
		o.onclick = this.handleAction.bind(this, m, 'change');
// E('button', { 'class': 'btn cbi-button-action', 'click': ui.createHandlerFn(this, 'handleAction', list[i].name, 'start'), 'disabled': isReadonlyView }, _('Start')),

		o = s.option(form.Button, '_restore_sel', _('Restore selected interfaces'));
		o.inputtitle = _('Restore');
		o.inputstyle = 'apply';
		o.onclick = this.handleAction.bind(this, m, 'restore');
// E('button', { 'class': 'btn cbi-button-action', 'click': ui.createHandlerFn(this, 'handleAction', list[i].name, 'stop'), 'disabled': isReadonlyView }, _('Stop')),

		s = m.section(form.TypedSection, '_utilities');
		s.render = L.bind(function(view, section_id) {
			return  E('div',{ 'class': 'cbi-section' }, [
				E('h3', {}, [ _('Utilities') ]),
				E('table', { 'class': 'table' }, [
					 E('td', { 'class': 'td left' }, [
						E('input', {
							'style': 'margin:5px 0',
							'type': 'text',
							'value': oui_be_queried
						}),
						E('span', { 'class': 'diag-action' }, [
							E('button', {
								'class': 'cbi-button cbi-button-action',
								'click': ui.createHandlerFn(view, 'handleQueryOUI')
							}, [ _('Query OUI vendor') ])
						])
					]),

					E('td', { 'class': 'td right' }, [
						E('button', {
							'class': 'cbi-button cbi-button-action',
							'click': ui.createHandlerFn(view, 'handleQueryVendor')
						}, [ _('List available ') + _('Vendor name') ])
					])
				]),
				E('pre', { 'class': 'command-output', 'style': 'display:none' })
			]);
		}, o, this);

		return m.render();
	}
});
