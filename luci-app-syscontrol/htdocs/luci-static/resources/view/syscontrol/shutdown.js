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
'require ui';
'require fs';

return view.extend({
    render: function() {
        return E('div', { class: 'cbi-map' }, [
            E('h2', _('System shutdown')),
            E('div', { class: 'cbi-section' }, [
                E('p', _('Shutting down the system will power off your device. Make sure all important processes are completed before proceeding.')),
                E('div', { class: 'cbi-section-actions' }, [
                    E('button', {
                        class: 'btn cbi-button cbi-button-negative',
                        click: ui.createHandlerFn(this, 'handleShutdown')
                    }, _('Shutdown System'))
                ])
            ]),
            E('div', { 'style': 'text-align: center; padding: 10px; font-style: italic;' }, [
                E('span', {}, [
                    _('© Dibuat oleh '),
                    E('a', { 
                        'href': 'https://github.com/bobbyunknow', 
                        'target': '_blank',
                        'style': 'text-decoration: none;'
                    }, 'BobbyUnknown')
                ])
            ])
        ]);
    },

    handleShutdown: function() {
        return ui.showModal(_('Confirm Shutdown'), [
            E('h4', { style: 'color: #d9534f; text-align: center;' }, _('Are you absolutely sure you want to shut down the system?')),
            E('p', { style: 'text-align: center;' }, _('This will power off your device. All running processes will be stopped.')),
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
                        ui.showModal(_('Shutting down...'), [
                            E('p', { 'class': 'spinning' }, _('The system is shutting down. GoodBye :)...'))
                        ]);
                        return fs.exec('/sbin/poweroff').catch(function(e) {
                            ui.addNotification(null, E('p', e.message));
                        });
                    })
                }, _('Shutdown'))
            ])
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
