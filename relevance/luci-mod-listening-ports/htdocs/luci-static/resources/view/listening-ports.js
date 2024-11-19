'use strict';
'require fs';
'require ui';
'require view';

return view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(fs.stat('/bin/netstat'), null),
		]).then(function(stat) {
			var logger = stat[0] ? stat[0].path : null;

			return fs.exec_direct(logger, [ '-peanut' ]).catch(function(err) {
				ui.addNotification(null, E('p', {}, _( err.message )));
				return '';
			});
		});
	},


	render_table: function(arr) {
        var table = E('table', { 'class': 'table', 'id': 'status' });
        table.appendChild(E('thead', {'class': 'thead'}, [ 
        	E('tr', { 'class': 'tr' }, [
            	E('td', { 'class': 'td right', 'width': '10%'}, _("Protocol")),
            	E('td', { 'class': 'td right', 'width': '10%'}, _("Local Address")),
            	E('td', { 'class': 'td right', 'width': '10%'}, _("Foreign Address")),
            	E('td', { 'class': 'td right', 'width': '10%'}, _("State")),
            	E('td', { 'class': 'td left', 'width': '40%'},  _("PID/Program name")),  
            ]),
        ]));
        for (var i = 0; i < arr.length; i++) {
            table.appendChild(E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td right', 'width': '10%'}, arr[i][1]),
                E('td', { 'class': 'td right', 'width': '10%'}, arr[i][4]),
                E('td', { 'class': 'td right', 'width': '10%'}, arr[i][5]),
                E('td', { 'class': 'td right', 'width': '10%'}, arr[i][6]),
                E('td', { 'class': 'td left', 'width': '40%'},  arr[i][7]),
            ]));
        }
        return table;
	},

	render: function(output) {
		var lines = output.trim().split(/\n/);
		var ipv4 = [], ipv6 = [];
		var ipv4_regex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;


		// Place IPv4 listening ports in the "ipv4" array and IPv6 ports in the "ipv6" array.  Ignore everything else: 
		for (var i = 0; i < lines.length; i++) {
			var t = lines[i].replace(/\s+/g, '|').split("|");
			if (t[5] == "LISTEN") {
				var ip = t[3].substr(0, t[3].lastIndexOf(":")).trim();
				var port = t[3].substr(t[3].lastIndexOf(":") + 1);
				t.unshift( Number(port) );
				if (ipv4_regex.test( ip )) {
					ipv4.push( t );
				} else {
					ipv6.push( t );
				}
			}
		}

		// Sort both the "ipv4" and "ipv6" arrays by the port number (index 0) for easier searching:
		ipv4.sort(function(a,b) {
			return a[0] - b[0];
		});
		ipv6.sort(function(a,b) {
			return a[0] - b[0];
		});

        return E('div', { 'class': 'cbi-map', 'id': 'map' }, [
            E('div', { 'class': 'cbi-section' }, [
                E('div', { 'class': 'left' }, [
                    E('h3', _('IPv4 Active Internet connections (servers only)')),
                    this.render_table( ipv4 )
                ]),
                E('div', { 'class': 'left' }, [
                    E('h3', _('IPv6 Active Internet connections (servers only)')),
                    this.render_table( ipv6 )
                ])
            ]),
        ]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
