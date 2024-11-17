'use strict';
'require baseclass';
'require fs';
'require uci';
'require rpc';

var conf = 'natmap';
var natmap_instance = 'natmap';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getInstances() {
	return L.resolveDefault(callServiceList(conf), {}).then(function(res) {
		try {
			return res[conf].instances || {};
		} catch (e) {}
		return {};
	});
}

function getStatus() {
	return getInstances().then(function(instances) {
		var promises = [];
		var status = {};
		for (var key in instances) {
			var i = instances[key];
			if (i.running && i.pid) {
				var f = '/var/run/natmap/' + i.pid + '.json';
				(function(k) {
					promises.push(fs.read(f).then(function(res) {
						status[k] = JSON.parse(res);
					}).catch(function(e){}));
				})(key);
			}
		}
		return Promise.all(promises).then(function() { return status; });
	});
}

return baseclass.extend({
	title: _('Active NATMap Portmap'),

	load: function() {
		return Promise.all([
			getStatus()
		]);
	},

	render: function(res) {
		var status = res[0];

		var table = E('table', { 'class': 'table cbi-section-table', 'id': 'natmap_status_table' }, [
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th' }, _('Name')),
				E('th', { 'class': 'th' }, _('Protocol')),
				E('th', { 'class': 'th' }, _('Inner Addr')),
				E('th', { 'class': 'th' }, _('Inner Port')),
				E('th', { 'class': 'th' }, _('Outer Addr')),
				E('th', { 'class': 'th' }, _('Outer Port')),
				E('th', { 'class': 'th cbi-section-actions' }, '')
			])
		]);

        var rows = [];
		if (status) {
			Object.keys(status).forEach(sid => {
				rows.push([
					status[sid].comment ? status[sid].comment + ' (' + sid + ')' : sid,
					status[sid].protocol,
					status[sid].inner_ip,
					status[sid].inner_port,
					status[sid].ip,
					status[sid].port
				])
			})
		};

		cbi_update_table(table, rows.sort(), E('em', _('There are no active portmap')));

		return table;
	}
});
