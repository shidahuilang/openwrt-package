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
'require view';
'require fs';
'require ui';

return view.extend({
    refreshInterval: null,

    load: function() {
        return Promise.all([
            L.resolveDefault(fs.read('/var/log/insomclash/app.log'), ''),
            L.resolveDefault(fs.read('/var/log/insomclash/core.log'), '')
        ]);
    },

    refreshLogs: function() {
        return this.load().then(function(data) {
            document.getElementById('applog').textContent = data[0] || _('No application log available');
            document.getElementById('corelog').textContent = data[1] || _('No core log available');
        });
    },

    toggleAutoRefresh: function(btn, selectEl) {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
            btn.textContent = _('Enable Auto-Refresh');
            selectEl.disabled = false;
        } else {
            var interval = parseInt(selectEl.value) * 1000;
            this.refreshInterval = setInterval(L.bind(this.refreshLogs, this), interval);
            btn.textContent = _('Disable Auto-Refresh');
            selectEl.disabled = true;
        }
    },

    render: function(data) {
        var appLog = data[0];
        var coreLog = data[1];
        
        // Mulai auto-refresh saat halaman dimuat
        var interval = 5000; // 5 detik
        this.refreshInterval = setInterval(L.bind(this.refreshLogs, this), interval);

        var logStyle = 'white-space: pre-wrap; overflow-y: auto; height: 400px; ' +
                       'background-color: #1e1e1e; color: #e0e0e0; ' +
                       'padding: 10px; font-family: monospace; font-size: 12px; ' +
                       'border: 1px solid #444;';

        return E('div', { 'class': 'cbi-map' }, [
            E('h2', _('InsomClash Logs')),
            E('div', { 'class': 'cbi-section', 'style': 'display: flex; justify-content: space-between;' }, [
                E('div', { 'style': 'width: 49%;' }, [
                    E('h3', _('App Log')),
                    E('pre', { 'id': 'applog', 'style': logStyle }, [ appLog || _('No application log available') ])
                ]),
                E('div', { 'style': 'width: 49%;' }, [
                    E('h3', _('Core Log')),
                    E('pre', { 'id': 'corelog', 'style': logStyle }, [ coreLog || _('No core log available') ])
                ])
            ]),
            E('div', { 'class': 'cbi-section' }, [
                E('button', {
                    'class': 'cbi-button cbi-button-remove',
                    'click': ui.createHandlerFn(this, function() {
                        return Promise.all([
                            fs.write('/var/log/insomclash/app.log', ''),
                            fs.write('/var/log/insomclash/core.log', '')
                        ]).then(function() {
                            document.getElementById('applog').textContent = _('Log cleared');
                            document.getElementById('corelog').textContent = _('Log cleared');
                            ui.addNotification(null, E('p', _('Logs have been cleared')), 'info');
                        }).catch(function(error) {
                            ui.addNotification(null, E('p', _('Failed to clear logs: ') + error.message), 'error');
                        });
                    })
                }, _('Clear Logs'))
            ]),
            E('div', { 'style': 'text-align: center; padding: 10px; font-style: italic;' }, [
                E('span', {}, [
                    _('© Dibuat oleh '),
                    E('a', { 
                        'href': 'https://github.com/bobbyunknow', 
                        'target': '_blank',
                        'style': 'text-decoration: none; color: #fa0202;'
                    }, 'BobbyUnknown')
                ])
            ])
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
