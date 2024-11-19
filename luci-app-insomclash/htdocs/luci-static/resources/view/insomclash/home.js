/* This is open source software, licensed under the MIT License.
 *
 * Copyright (C) 2024 BobbyUnknown
 *
 * Description:
 * This software provides a tunneling application for OpenWrt using Mihomo core.
 * The application allows users to configure and manage proxy rules, connections,
 * and network traffic routing through a user-friendly web interface, enabling
 * advanced networking capabilities and traffic control on OpenWrt routers.
 */

'use strict';
'require form';
'require fs';
'require ui';
'require view';

return view.extend({
    handleAction: function(name, action) {
        var commands = [];
        if (action === 'start') {
            commands = ['start', 'enable'];
        } else if (action === 'stop') {
            commands = ['stop', 'disable'];
        } else {
            commands = [action];
        }

        return Promise.all(commands.map(cmd => 
            fs.exec('/etc/init.d/insomclash', [cmd])
                .then(function(result) {
                    console.log('Command:', cmd, 'Result:', result);
                    return result;
                })
        )).then(function(results) {
            var success = results.every(res => res.code === 0);
            if (success) {
                var message = _('InsomClash has been ' + (action === 'start' ? 'started' : action === 'stop' ? 'stopped' : action + 'ed') + '.');
                localStorage.setItem('insomclashNotification', JSON.stringify({
                    type: 'success',
                    message: message
                }));
                setTimeout(() => window.location.reload(), 1000);
            } else {
                // Log error details
                console.error('Command failed:', results);
                var errorMsg = results.map(r => r.stderr || r.stdout).join('\n');
                ui.addNotification(null, E('p', _('Failed to ' + action + ' InsomClash: ' + errorMsg)), 'danger');
            }
        }.bind(this)).catch(function(err) {
            console.error('Error:', err);
            ui.addNotification(null, E('p', _('Error: ' + err)), 'danger');
        });
    },

    load: function() {
        return fs.exec('/etc/init.d/insomclash', ['status'])
            .then(function(res) {
                return res;
            });
    },

    render: function(data) {
        var m, s, o, footerSection;
        var running = (data && data.stdout) ? data.stdout.trim() === "running" : false;

        var storedNotification = localStorage.getItem('insomclashNotification');
        if (storedNotification) {
            var notification = JSON.parse(storedNotification);
            ui.addNotification(null, E('p', _(notification.message)), notification.type);
            localStorage.removeItem('insomclashNotification');
        }

        m = new form.Map('insomclash', _('InsomClash'), _('Mihomo Tproxy'));

        s = m.section(form.NamedSection, 'config', 'insomclash');

        o = s.option(form.DummyValue, '_status');
        o.rawhtml = true;
        o.cfgvalue = function(section_id) {
            var statusText = running ? '<span style="color:green;">Running</span>' : '<span style="color:red;">Stopped</span>';
            return E('div', { class: 'cbi-value' }, [
                E('label', { class: 'cbi-value-title' }, _('Service Status')),
                E('div', { class: 'cbi-value-field cbi-section-node-status' }, statusText)
            ]);
        };

        o = s.option(form.Button, '_start', _('Start InsomClash'));
        o.inputtitle = _('Start InsomClash');
        o.onclick = L.bind(this.handleAction, this, 'insomclash', 'start');
        o.inputstyle = 'save';
        if (running) {
            o.inputstyle = 'reset';
            o.readonly = true;
        }

        o = s.option(form.Button, '_stop', _('Stop InsomClash'));
        o.inputtitle = _('Stop InsomClash');
        o.onclick = L.bind(this.handleAction, this, 'insomclash', 'stop');
        o.inputstyle = 'reset';
        if (!running) {
            o.inputstyle = 'reset';
            o.readonly = true;
        }

        if (running) {
            o = s.option(form.Button, '_restart', _('Restart InsomClash'));
            o.inputtitle = _('Restart InsomClash');
            o.onclick = L.bind(this.handleAction, this, 'insomclash', 'restart');
            o.inputstyle = 'apply';

            o = s.option(form.Button, '_opendashboard', _('Open Dashboard'));
            o.inputtitle = _('Open Dashboard');
            o.inputstyle = 'apply';
            o.onclick = function() {
                var hostname = window.location.hostname;
                window.open('http://' + hostname + ':9090/ui/?hostname=' + hostname + '&port=9090#/proxies', '_blank');
            };
        }

        footerSection = m.section(form.NamedSection, 'footer', 'footer');
        footerSection.render = function() {
            return E('div', { 'style': 'text-align: center; padding: 10px; font-style: italic;' }, [
                E('span', {}, [
                    _('© Dibuat oleh '),
                    E('a', { 
                        'href': 'https://github.com/bobbyunknow', 
                        'target': '_blank',
                        'style': 'text-decoration: none; color: #fa0202;'
                    }, 'BobbyUnknown')
                ])
            ]);
        };

        return m.render();
    },
    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
