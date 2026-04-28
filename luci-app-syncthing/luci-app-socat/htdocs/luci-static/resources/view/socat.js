'use strict';
'require view';
'require form';
'require rpc';
'require uci';
'require poll';
'require network';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

return view.extend({
	load: function () {
		return Promise.all([
			network.getHostHints()
		]);
	},

	render: function (data) {
		var m, s, o;
		var hostHints = data[0];

		m = new form.Map('luci_socat', _('Socat'), _('Socat is a relay for bidirectional data transfer between two independent data channels.'));

		s = m.section(form.NamedSection, 'global', 'global', _('Global Settings'));
		s.addremove = false;

		o = s.option(form.Flag, 'enable', _('Enabled'));
		o.rmempty = true;

		s = m.section(form.GridSection, 'config', _('Port Forwarding'));
		s.addremove = true;
		s.anonymous = true;
		s.sortable = true;
		s.nodescriptions = true;

		var super_handleAdd = s.handleAdd;
		s.handleAdd = function (ev) {
			var uuid = Array.from({length: 32}, () => Math.floor(Math.random() * 16).toString(16)).join('');
			return super_handleAdd.call(this, ev, uuid);
		};

		s.modaltitle = function (section_id) {
			return _('Socat Configuration');
		};

		o = s.option(form.Flag, 'enable', _('Enabled'));
		o.editable = true;
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.DummyValue, '_status', _('Status'));
		o.modalonly = false;
		o.cfgvalue = function() {
			return '-';
		};

		poll.add(function () {
			return callServiceList('luci_socat').then(function (res) {
				var instances = (res && res.luci_socat && res.luci_socat.instances) ? res.luci_socat.instances : {};

				document.querySelectorAll('tr[data-sid]').forEach(function (row) {
					var sid = row.getAttribute('data-sid');
					if (!sid) return;
					sid = sid.trim();

					var cell = row.querySelector('td[data-name="_status"]');
					if (!cell) return;

					var isRunning = !!instances[sid];

					cell.innerHTML = isRunning ? '🟢' : '🔴';
				});
			});
		});

		o = s.option(form.Value, 'remarks', _('Remarks'));

		o = s.option(form.ListValue, "protocol", _("Protocol Type"));
		o.value("port_forwards", _("Port Forwarding"));
		o.modalonly = true;

		o = s.option(form.ListValue, "family", _("Listen Address Family"));
		o.value("", _("IPv4 and IPv6"));
		o.value("4", _("IPv4 Only"));
		o.value("6", _("IPv6 Only"));
		o.depends("protocol", "port_forwards");
		o.modalonly = true;

		o = s.option(form.ListValue, "proto", _("Listen Protocol"));
		o.value("tcp", "TCP");
		o.value("udp", "UDP");
		o.depends("protocol", "port_forwards");
		o.textvalue = function (section_id) {
			var family_val = uci.get('luci_socat', section_id, 'family');
			var proto_val = uci.get('luci_socat', section_id, 'proto');
			if (proto_val) {
				if (family_val === '4') return 'IPv4-' + proto_val.toUpperCase();
				if (family_val === '6') return 'IPv6-' + proto_val.toUpperCase();
				return 'ALL-' + proto_val.toUpperCase();
			}
		};

		o = s.option(form.Value, "listen_port", _("Listen Port"));
		o.datatype = "portrange";
		o.rmempty = false;
		o.depends("protocol", "port_forwards");

		o = s.option(form.Flag, "reuseaddr", _("Reuse Port"), _("Allow binding to the port even when previous connections are in TIME_WAIT, preventing restart failures."));
		o.default = "1";
		o.rmempty = false;
		o.modalonly = true;

		o = s.option(form.ListValue, "dest_proto", _("Destination Protocol"));
		o.value("tcp4", "IPv4-TCP");
		o.value("udp4", "IPv4-UDP");
		o.value("tcp6", "IPv6-TCP");
		o.value("udp6", "IPv6-UDP");
		o.depends("protocol", "port_forwards");

		o = s.option(form.Value, 'dest_ip', _('Destination Address'));
		o.rmempty = false;
		o.depends("protocol", "port_forwards");
		o.value('127.0.0.1', ('127.0.0.1 (localhost)'));
		hostHints.getMACHints().forEach(function (entry) {
			var mac = entry[0];
			var hint = entry[1] || mac;
			var ip = hostHints.getIPAddrByMACAddr(mac);
			if (ip)
				o.value(ip, '%s (%s)'.format(ip, hint));
		});

		o = s.option(form.Value, "dest_port", _("Destination Port"));
		o.datatype = "portrange";
		o.rmempty = false;

		o = s.option(form.Flag, "firewall_accept", _("Open Firewall Port"));
		o.editable = true;
		o.default = "0";
		o.rmempty = false;

		return m.render();
	}
});
