'use strict';
'require fs';
'require ui';
'require view';

return view.extend({
	nds_sep: 0,
	nds_clients: 0,

	load: function() {
		return Promise.all([
			L.resolveDefault(fs.stat('/usr/bin/ndsctl'), null),
		]).then(function(stat) {
			var logger = stat[0] ? stat[0].path : null;

			return fs.exec_direct(logger, [ 'status' ]).catch(function(err) {
				ui.addNotification(null, E('p', {}, _( err.message )));
				return '';
			});
		});
	},

	render_table: function(lines, start) {
		var table, idx, data, client = false;
		var pattern = /^Client \d+/;

		var table = E('table', { 'class': 'table', 'id': 'status' });
		if (lines.length == 1) {
			table.appendChild(E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, _("ndsctl: nodogsplash probably not started (Error: Connection refused)"))
			]));
		} else {
			for (var i = start; i < lines.length; i++) {
				if (lines[i].substring(0,3) == "===") {
					this.nds_sep = i + 1
					break
				} 
				if (pattern.test(lines[i + 1]) || lines[i] == '') {
					if (this.nds_clients < this.nds_sep) {
						client = true;
						this.nds_clients = i + 1;
					}
				}
				if (!client) {
					data = lines[i].split(":")
					idx = data[0];
					data.shift();
					data = data.join(":").trim();
					if (data.substring(0,7) == "http://" || data.substring(0,8) == "https://") {
						data = E('a', { 'href': data, 'target': '_blank' }, data);
					}
					table.appendChild(E('tr', { 'class': 'tr' }, [
						E('td', { 'class': 'td left', 'width': '33%' }, _(idx)),
						E('td', { 'class': 'td left' }, data)
					]));
				}
			}
		}
		return table;
	},
	
	render_status: function(lines) {
		return E('div', { 'class': 'left' }, [
			E('h2', _('NoDogSplash Status')), this.render_table(lines, 3)
		]);
	},
	
	render_client_summary: function(lines) {
		return E('div', { 'class': 'left' }, [
			E('h3', _('Clients List')),	this.render_table(lines, this.nds_sep)
		]);
	},
	
	render_mac_summary: function(lines) {
		return E('div', { 'class': 'left' }, [
			E('h3', _('Type of Clients')), this.render_table(lines, this.nds_sep)
		]);
	},
	
	render_client_list: function(lines) {
		var s;
		if (this.nds_clients == 0)
			return '';
		var clients = [];
		var count = 1;
		while (this.nds_clients + 1 < this.nds_sep) {
			lines[ this.nds_clients + 1 ] = lines[ this.nds_clients + 1 ].trim().replace("MAC", "/ MAC");
			s = _("Client") + " " + count + " (" + lines[ this.nds_clients + 1 ].split("/")[1].trim() + ")";
			lines[ this.nds_clients + 1 ] = lines[ this.nds_clients + 1 ].split("/")[0];
			clients.push( E('h3', s), this.render_table(lines, this.nds_clients + 1) );
			count++;
		}
		return E('div', { 'class': 'left' }, clients);
	},

	render: function(output) {
		var lines = output.trim().split(/\n/);
		return E('div', { 'class': 'cbi-map', 'id': 'map' }, [
			this.render_status(lines),
			this.render_client_summary(lines),
			this.render_client_list(lines),
			this.render_mac_summary(lines)
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
