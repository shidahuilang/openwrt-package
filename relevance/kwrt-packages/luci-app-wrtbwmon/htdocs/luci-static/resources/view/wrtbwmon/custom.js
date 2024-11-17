'use strict';
'require fs';
'require ui';
'require view';

return view.extend({
	load: function() {
		return fs.trimmed('/etc/wrtbwmon.user').catch(function(err) {
			ui.addNotification(null, E('p', {}, _('Unable to load the customized hostname file: ' + err.message)));
			return '';
		});
	},

	render: function(data) {
		return E('div', {'class': 'cbi-map'}, [
			E('h2', {'name': 'content'}, [ _('Usage - Custom User File') ]),
			E('div', {'class': 'cbi-map-descr'}, [
				_('Each line must have the following format:'),
				E('em', {'style': 'color:red'}, '00:aa:bb:cc:ee:ff,hostname')
			]),
			E('div', {'class': 'cbi-section'}, [
				E('textarea', {
					'id': 'custom_hosts',
					'style': 'width: 100%;padding: .5em;',
					'rows': 20
				}, data)
			])
		]);
	},

	handleSave: function(ev) {
		var map = document.querySelector('#custom_hosts');
		return fs.write('/etc/wrtbwmon.user', map.value.trim().replace(/\r\n/g, '\n') + '\n');
	},
	handleSaveApply: null,
	handleReset: null
});
