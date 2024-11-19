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
'require rpc';
'require poll';

var callSystemInfo = rpc.declare({
    object: 'system',
    method: 'info'
});

return view.extend({
    load: function() {
        console.log('Load function called');
        return callSystemInfo().then(function(data) {
            console.log('RAM information loaded:', JSON.stringify(data.memory));
            return {
                memory: data.memory
            };
        }).catch(function(error) {
            console.error('Error loading RAM information:', error);
            throw error;
        });
    },

    updateMemoryStatus: function(memory) {
        console.log('Updating memory status with:', memory);
        if (!memory) {
            console.error('Memory information is missing');
            return;
        }
        var totalMB = Math.round(memory.total / 1024 / 1024);
        var freeMB = Math.round(memory.free / 1024 / 1024);
        var cachedMB = Math.round(memory.cached / 1024 / 1024);
        var usedMB = totalMB - freeMB - cachedMB;
        var usedPercent = Math.round((usedMB / totalMB) * 100);

        var memoryStatusElement = document.getElementById('memory-status');
        if (memoryStatusElement) {
            memoryStatusElement.innerHTML = '';
            memoryStatusElement.appendChild(
                E('div', { 'class': 'table' }, [
                    E('div', { 'class': 'tr' }, [
                        E('div', { 'class': 'td left' }, _('Total RAM:')),
                        E('div', { 'class': 'td left' }, totalMB + ' MB')
                    ]),
                    E('div', { 'class': 'tr' }, [
                        E('div', { 'class': 'td left' }, _('Used RAM:')),
                        E('div', { 'class': 'td left' }, usedMB + ' MB (' + usedPercent + '%)')
                    ]),
                    E('div', { 'class': 'tr' }, [
                        E('div', { 'class': 'td left' }, _('Cached RAM:')),
                        E('div', { 'class': 'td left' }, cachedMB + ' MB')
                    ]),
                    E('div', { 'class': 'tr' }, [
                        E('div', { 'class': 'td left' }, _('Free RAM:')),
                        E('div', { 'class': 'td left' }, freeMB + ' MB')
                    ])
                ])
            );
        } else {
            console.error('Memory status element not found');
        }
    },

    render: function(data) {
        console.log('Render function called with:', JSON.stringify(data));
        var view = E('div', { 'class': 'cbi-map' }, [
            E('h2', _('RAM Status')),
            E('div', { 'class': 'cbi-section' }, [
                E('div', { 'id': 'memory-status' })
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

        requestAnimationFrame(L.bind(function() {
            this.updateMemoryStatus(data.memory);
        }, this));

        return view;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null,

    poll: {
        interval: 5,
        task: function() {
            console.log('Polling task running');
            return callSystemInfo().then(L.bind(function(data) {
                console.log('Polling task received RAM information:', JSON.stringify(data.memory));
                this.updateMemoryStatus(data.memory);
            }, this)).catch(function(error) {
                console.error('Error in polling task:', error);
            });
        }
    }
});
