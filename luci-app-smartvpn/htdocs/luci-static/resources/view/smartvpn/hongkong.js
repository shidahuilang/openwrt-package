'use strict';
'require fs';
'require ui';

var filename = '/etc/smartvpn/user_hongkong.txt';

return L.view.extend({
	load: function() {
		return L.resolveDefault(fs.read_direct(filename), '');
	},
	handleSave: function(ev) {
		var value = ((document.querySelector('textarea').value || '').trim().toLowerCase().replace(/\r\n/g, '\n')) + '\n';
		return fs.write(filename, value)
			.then(function(rc) {
				document.querySelector('textarea').value = value;
				ui.addNotification(null, E('p', _('Changes have been saved. You should restart SmartVPN to take effect.')), 'info');
			}).catch(function(e) {
				ui.addNotification(null, E('p', _('Unable to save changes: %s').format(e.message)));
			});
	},
	render: function(blacklist) {
		return E([
			E('p', {},
				_('Listed below are your customized hosts must be accessed via Hongkong gateway.<br /> \
				Please note: add only one domain per line. Make sure the hosts accessed much quicker from Hongkong.')),
			E('p', {},
				E('textarea', {
					'style': 'width: 100% !important; padding: 5px; font-family: monospace',
					'spellcheck': 'false',
					'wrap': 'off',
					'rows': 25
				}, [ blacklist != null ? blacklist : 'empty' ])
			)
		]);
	},
	handleReset: function(ev) {
		L.resolveDefault(fs.read_direct(filename),'').then(function(hostlist) {
			document.querySelector('textarea').value = hostlist;
			ui.addNotification(null, E('p', _('Restore hosts list to original content')), 'info');	
		}).catch(function(e) {
			ui.addNotification(null, E('p', _('Unable to read file: %s').format(e.message)));
		});
	},
	handleSaveApply: null
});
