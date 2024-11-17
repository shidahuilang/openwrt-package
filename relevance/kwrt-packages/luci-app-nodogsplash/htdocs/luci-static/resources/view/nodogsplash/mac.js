'use strict';
'require form';
'require ui';
'require view';
'require uci';
'require fs';

// Project code format is tabs, not spaces
return view.extend({
	can_block: true,
	auth_list: [],
	allow_list: [],
	block_list: [],
	trust_list: [],
	allow_orig: [],
	block_orig: [],
	trust_orig: [],
	client_list: [],

	load: function () {
		return Promise.all([
			uci.load('nodogsplash')
		]).then(function(stat) {
			return fs.exec_direct("/usr/bin/ndsctl", [ 'json' ]).catch(function(err) {
				ui.addNotification(null, E('p', {}, err.message ));
				return '';
			});
		});
	},

	ndsctl: function(group, div, cmd) {
		var mac = div.previousSibling.getElementsByClassName('mac')[0].innerHTML;
		var is_active = this.client_list[mac].state != null;
		var no_un = cmd.replace(/un|de/, "");
		
		fs.exec('/usr/bin/ndsctl', [ cmd, mac ]).then(function(res) {
			ui.addNotification(null, E('p', [ res.stdout ]), res.code ? 'error' : 'success')
		}).catch(function(err) {
			ui.addNotification(null, E('p', [ err ]), 'error')
		});
		if (cmd != no_un)
		{
			group = group.filter( check => check != mac );
			div.getElementsByClassName('cbi-un' + no_un + '-button')[0].classList.add("hidden");
			div.getElementsByClassName('cbi-' + no_un + '-button')[0].classList.remove("hidden");
		} else {
			group = group.push(mac);
			div.getElementsByClassName('cbi-' + no_un + '-button')[0].classList.add("hidden");
			div.getElementsByClassName('cbi-un' + no_un + '-button')[0].classList.remove("hidden");
		}
		uci.set_first("nodogsplash", "nodogsplash", "trustedmac", group.length > 0 ? group : null);
	},

	trust_mac: function(elem, cmd) {
		this.ndsctl(this.trust_orig, elem.currentTarget.parentNode, 'trust');
	},

	untrust_mac: function(elem, cmd) {
		this.ndsctl(this.trust_orig, elem.currentTarget.parentNode, 'untrust');
	},

	allow_mac: function(elem, cmd) {
		this.ndsctl(this.allow_orig, elem.currentTarget.parentNode, 'allow');
	},

	unallow_mac: function(elem, cmd) {
		this.ndsctl(this.allow_orig, elem.currentTarget.parentNode, 'unallow');
	},

	block_mac: function(elem, cmd) {
		this.ndsctl(this.allow_orig, elem.currentTarget.parentNode, 'block');
	},

	unblock_mac: function(elem, cmd) {
		this.ndsctl(this.allow_orig, elem.currentTarget.parentNode, 'unblock');
	},

	auth_mac: function(elem, cmd) {
		this.ndsctl(this.auth_orig,  elem.currentTarget.parentNode, 'auth');
	},

	unauth_mac: function(elem, cmd) {
		this.ndsctl(this.auth_orig,  elem.currentTarget.parentNode, 'deauth');
	},

	render_button: function(txt, is_hidden) {
		var cname = txt.toLowerCase();
		return E('button', {
			'class': 'cbi-button cbi-button-action cbi-' + cname + '-button cbi-' + cname.replace('un', '') + '-group' + (is_hidden ? ' hidden' : ''),
			'click': ui.createHandlerFn(this, cname + '_mac')
		}, _(txt + ' MAC'));
	},

	render_client: function(client) {
		return E('tr', { 'class': 'tr mac-' + client.mac.replaceAll(":", "") }, [
			E('td', { 'class': 'td left', 'style': 'width: 50%;' }, [
				E('span', { style: 'font-size:medium;', class: 'mac' }, client.mac),
				E('span', {}, client.ip != null ? ' (' + client.ip + ')' : ''),
				E('ul', { style: "margin-left: 20px" }, [
					E('li', { style: "list-style-type: circle;" }, [
						E('span', { style: "font-weight:bold;" }, _("Client Status") + ": "),
						E('span', {}, client.state != null ? _(client.state) : _('Disconnected'))
					]),
					client.state != null ? E('li', { style: "list-style-type: circle;" }, [
						E('span', { style: "font-weight:bold;" }, _("Active Since") + ": "),
						E('span', {}, new Date(client.active * 1000)),
					]) : E('span', {})
				]),
			]),
			E('td', { 'class': 'diag-action', 'style': 'width: 50%; vertical-align: top;' }, [
				this.render_button('Trust',   client.trusted),
				this.render_button('Untrust', !client.trusted),
				this.render_button('Allow',   client.allowed  || this.can_block),
				this.render_button('Unallow', !client.allowed || this.can_block),
				this.render_button('Block',   client.blocked  || !this.can_block),
				this.render_button('Unblock', !client.blocked || !this.can_block),
			])
		]);
	},

	render_list: function(table, list) {
		for (let i in list) {
			// Render the client data:
			var client = list[i].mac == null ? { mac: list[i] } : list[i];
			var mac = client.mac = client.mac.toLowerCase();
			client.trusted = this.trust_list.includes(mac);
			client.allowed = this.allow_list.includes(mac);
			client.blocked = this.block_list.includes(mac);
			this.client_list[ mac ] = client;
			table.appendChild( this.render_client( client ) );

			// Remove the client from each of the mac lists:
			this.trust_list = this.trust_list.filter( check => check != mac );
			this.allow_list = this.allow_list.filter( check => check != mac );
			this.block_list = this.block_list.filter( check => check != mac );
		}
		return table;
	},

	lowercase_list: function(table) {
		for (let i in table)
			table[i] = table[i].toLowerCase();
		return table;
	},

	render: function(data) {
		var m, s, o;
		var sections = uci.sections('nodogsplash');
		this.allow_orig = this.allow_list = this.lowercase_list( sections[0].allowedmac != null ? sections[0].allowedmac : [] );
		this.block_orig = this.block_list = this.lowercase_list( sections[0].blockedmac != null ? sections[0].blockedmac : [] );
		this.trust_orig = this.trust_list = this.lowercase_list( sections[0].trustedmac != null ? sections[0].trustedmac : [] );
		this.can_block = sections[0].macmechanism == 'block';

		// Process the current clients first, creating table for use later:
		var table = E('table', { 'class': 'table mac-table' });
		data = JSON.parse( (data == '' || data == null) ? '{"clients": {}}' : data );
		this.render_list( table, data.clients );

		// Process the trusted, allowed and blocked MAC address lists:
		this.render_list( table, this.trust_list );
		this.render_list( table, this.allow_list );
		this.render_list( table, this.block_list );

		// Actually render the page:
		m = new form.Map('nodogsplash', _('MAC Mechanism'));
		s = m.section(form.TypedSection, 'nodogsplash');
		s.anonymous = true;

		o = s.option(form.ListValue, 'macmechanism', _("MAC Access Mechanism"), _("MAC addresses that are / are not allowed to access the splash page"));
		o.value('block', _("Block MACs"));
		o.value('allow', _("Allow MACs"));
		o.default = 'block';
		o.rmempty = false;
		o.editable = false;

		s = m.section(form.TypedSection, 'nodogsplash', _('Clients'));
		s.anonymous = true;
		var ClientTable = form.DummyValue.extend({
			renderWidget: function(section_id, option_index, cfgvalue) {
				return table;
			}
		});
		o = s.option(ClientTable);

		return m.render();
	}
});
