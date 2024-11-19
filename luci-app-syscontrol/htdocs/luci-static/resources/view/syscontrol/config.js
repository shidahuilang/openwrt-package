/*
 * This is open source software, licensed under the MIT License.
 *
 * Copyright (C) 2024 BobbyUnknown
 *
 * Description:
 * This software provides a RAM release scheduling application for OpenWrt.
 * The application allows users to configure and automate the process of 
 * releasing RAM on their OpenWrt router at specified intervals, helping
 * to optimize system performance and resource management through a 
 * user-friendly web interface.
 */

'use strict';
'require form';
'require view';
'require uci';
'require ui';
'require fs';
'require tools.widgets as widgets';

return view.extend({
    render: function() {
        var m, s, o, footerSection;

        m = new form.Map('77_syscontrol', _('RAM Release Schedule'),
            _('Configure schedule for automatic RAM release.'));

        s = m.section(form.NamedSection, 'schedule', 'ram_release', _('Schedule Settings'));
        s.anonymous = true;
        s.addremove = false;

        o = s.option(form.Flag, 'enabled', _('Enable'),
            _('Enable automatic RAM release schedule'));
        o.rmempty = false;
        o.write = function(section_id, value) {
            form.Flag.prototype.write.apply(this, arguments);
            return fs.exec('/etc/init.d/ram_release', [value === '1' ? 'enable' : 'disable'])
                .then(function() {
                    return fs.exec('/etc/init.d/ram_release', [value === '1' ? 'start' : 'stop']);
                });
        };

        o = s.option(form.DummyValue, '_status', _('Service Status'));
        o.rawhtml = true;
        o.load = function(section_id) {
            return fs.exec('/etc/init.d/ram_release', ['status']).then(function(res) {
                if (res.code === 0) {
                    return '<span style="color:green;font-weight:bold;">Running</span>';
                } else {
                    return '<span style="color:red;font-weight:bold;">Stopped</span>';
                }
            }).catch(function(err) {
                ui.addNotification(null, E('p', _('Error checking service status: ') + err.message), 'error');
                return '<span style="color:gray;font-weight:bold;">Unknown</span>';
            });
        };

        o = s.option(form.Value, 'time', _('Time'),
            _('Enter time for RAM release (24-hour format, e.g. 23:30)'));
        o.datatype = 'string';
        o.validate = function(section_id, value) {
            if (!/^([01]\d|2[0-3]):([0-5]\d)$/.test(value)) {
                return _('Invalid time format. Please use HH:MM (24-hour format).');
            }
            return true;
        };

        o = s.option(form.MultiValue, 'days', _('Days'),
            _('Select days for RAM release'));
        o.multiple = true;
        o.value('mon', _('Monday'));
        o.value('tue', _('Tuesday'));
        o.value('wed', _('Wednesday'));
        o.value('thu', _('Thursday'));
        o.value('fri', _('Friday'));
        o.value('sat', _('Saturday'));
        o.value('sun', _('Sunday'));

        footerSection = m.section(form.NamedSection, 'footer', 'footer');
        footerSection.render = function() {
            return E('div', { 'style': 'text-align: center; padding: 10px; font-style: italic;' }, [
                E('span', {}, [
                    _('© Dibuat oleh '),
                    E('a', { 
                        'href': 'https://github.com/bobbyunknow', 
                        'target': '_blank',
                        'style': 'text-decoration: none;'
                    }, 'BobbyUnknown')
                ])
            ]);
        };

        return m.render().then(function(rendered) {
            console.log('Form rendered:', rendered);
            console.log('Enabled:', uci.get('77_syscontrol', 'schedule', 'enabled'));
            console.log('Time:', uci.get('77_syscontrol', 'schedule', 'time'));
            console.log('Days:', uci.get('77_syscontrol', 'schedule', 'days'));
            return rendered;
        }).catch(function(err) {
            console.error('Error rendering form:', err);
            ui.addNotification(null, E('p', _('Error loading configuration: ' + err.message)), 'error');
        });
    }
});
