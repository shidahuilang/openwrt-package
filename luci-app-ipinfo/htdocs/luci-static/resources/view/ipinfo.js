/* This is free software, licensed under the Apache License, Version 2.0
 *
 * Copyright (C) 2024 Hilman Maulana <hilman0.0maulana@gmail.com>
 */

'use strict';
'require view';
'require form';

return view.extend({
	render: function () {
		var m, s, o;
		m = new form.Map('ipinfo', _('IP Information'),
			_('Shows public IP information in Overview LuCI with <a %s>ip.guide</a>.').format('href="https://ip.guide" target="_blank"'));
		s = m.section(form.NamedSection, 'config', 'ipinfo');
		s.anonymous = true;

		o = s.option(form.Flag, 'enable', _('Enable'),
			_('Enable or disable service.'));
		o.rmempty = false;

		o = s.option(form.MultiValue, 'isp', _('Provider Information'),
			_('Select ISP information to display.'));
		o.display_size = '4';
		o.value('ip', _('Public IP'));
		o.value('name', _('Provider'));
		o.value('organization', _('Organization'));
		o.value('asn', _('AS Number'));

		o = s.option(form.MultiValue, 'loc', _('Location Information'),
			_('Select location information to display.'));
		o.display_size = '3';
		o.value('city', _('City'));
		o.value('country', _('Country'));
		o.value('timezone', _('Timezone'));

		o = s.option(form.MultiValue, 'co', _('Coordinate Information'),
			_('Select coordinate information to display.'));
		o.display_size = '2';
		o.value('latitude', _('Latitude'));
		o.value('longitude', _('Longitude'));

		return m.render();
	},
});
