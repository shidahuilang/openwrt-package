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
'require view';
'require rpc';
'require ui';
'require uci';

var callReboot = rpc.declare({
    object: 'system',
    method: 'reboot',
    expect: { result: 0 }
});

var callForceReboot = rpc.declare({
    object: 'system',
    method: 'reboot',
    params: [ '-f' ],
    expect: { result: 0 }
});

return view.extend({
    load: function() {
        return uci.changes();
    },

    render: function(changes) {
        var body = E([
            E('h2', _('System reboot')),
            E('p', {}, _('Reboots the operating system of your device'))
        ]);

        for (var config in (changes || {})) {
            body.appendChild(E('p', { 'class': 'alert-message warning' },
                _('Warning: There are unsaved changes that will get lost on reboot!')));
            break;
        }

        body.appendChild(E('hr'));
        body.appendChild(E('button', {
            'class': 'cbi-button cbi-button-action important',
            'click': ui.createHandlerFn(this, 'handleReboot', false)
        }, _('Normal Reboot')));
        
        body.appendChild(E('button', {
            'class': 'cbi-button cbi-button-negative important',
            'click': ui.createHandlerFn(this, 'handleReboot', true)
        }, _('Force Reboot')));

        body.appendChild(E('div', { 'style': 'text-align: center; padding: 10px; font-style: italic;' }, [
            E('span', {}, [
                _('© Dibuat oleh '),
                E('a', { 
                    'href': 'https://github.com/bobbyunknow', 
                    'target': '_blank',
                    'style': 'text-decoration: none;'
                }, 'BobbyUnknown')
            ])
        ]));

        return body;
    },

    handleReboot: function(ev, force) {
        var rebootCall = force ? callForceReboot : callReboot;
        var rebootType = force ? _('Force Reboot') : _('Normal Reboot');
        
        ui.showModal(_('Confirm Reboot'), [
            E('h4', { style: 'color: #d9534f; text-align: center;' }, _('Are you absolutely sure you want to reboot the system?')),
            E('p', { style: 'text-align: center;' }, _('This will restart your device. All running processes will be stopped.')),
            E('div', { class: 'right' }, [
                E('button', {
                    'class': 'btn',
                    'click': ui.hideModal
                }, _('Cancel')),
                ' ',
                E('button', {
                    'class': 'btn btn-danger',
                    'click': ui.createHandlerFn(this, function() {
                        ui.hideModal();
                        return rebootCall().then(function(res) {
                            if (res != 0) {
                                ui.addNotification(null, E('p', _('The reboot command failed with code %d').format(res)));
                                throw new Error('Reboot failed');
                            }

                            ui.showModal(_('Rebooting…'), [
                                E('p', { 'class': 'spinning' }, _('Waiting for device...'))
                            ]);

                            var checkInterval = window.setInterval(function() {
                                fetch(window.location.href, { method: 'HEAD', cache: 'no-cache' })
                                    .then(function() {
                                        window.clearInterval(checkInterval);
                                        window.location.reload();
                                    })
                                    .catch(function() {});
                            }, 5000);

                            window.setTimeout(function() {
                                ui.showModal(_('Rebooting…'), [
                                    E('p', { 'class': 'spinning alert-message warning' },
                                        _('Device unreachable! Still waiting for device...'))
                                ]);
                            }, 150000);
                        }).catch(function(e) {
                            ui.addNotification(null, E('p', e.message));
                        });
                    })
                }, rebootType)
            ])
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
