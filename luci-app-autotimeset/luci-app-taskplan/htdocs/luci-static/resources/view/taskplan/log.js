'use strict';
'require view';
'require ui';
'require poll';
'require fs';

return view.extend({
    load: function() {
        return fs.read('/etc/taskplan/taskplan.log').catch(function(err) {
            console.error('Failed to read log file:', err);
            return '';
        });
    },

    handleClearLog: function() {
        var self = this;
        return fs.write('/etc/taskplan/taskplan.log', '').then(function() {
            ui.addNotification(null, E('p', {}, _('Log cleared')));
            self.updateLogDisplay();
        }).catch(function(err) {
            ui.addNotification(null, E('p', { 'class': 'alert-message' }, _('Failed to clear log: ') + err.message));
        });
    },

    handleReverseLog: function() {
        this.reverse = !this.reverse;
        this.updateLogDisplay();
    },

    handleDownloadLog: function() {
        var self = this;
        fs.read('/etc/taskplan/taskplan.log').then(function(content) {
            if (content) {
                var blob = new Blob([content], { type: 'text/plain' });
                var url = URL.createObjectURL(blob);
                var a = document.createElement('a');
                a.href = url;
                a.download = 'taskplan.log';
                a.click();
                URL.revokeObjectURL(url);
            } else {
                ui.addNotification(null, E('p', {}, _('Log is empty')));
            }
        });
    },

    updateLogDisplay: function() {
        var self = this;
        fs.read('/etc/taskplan/taskplan.log').then(function(content) {
            var logArea = document.getElementById('log_content');
            if (logArea) {
                if (self.reverse) {
                    logArea.value = content.split('\n').reverse().join('\n');
                } else {
                    logArea.value = content;
                }
                // 如果不是反向模式，自动滚动到底部
                if (!self.reverse) {
                    logArea.scrollTop = logArea.scrollHeight;
                }
            }
        });
    },

    render: function(logContent) {
        this.reverse = false;

        return E('div', { 'class': 'view' }, [
            E('div', { 'class': 'cbi-map' }, [
                // 标题
                E('h2', {}, _('Task Plan Log Viewer')),

                E('div', { 'class': 'cbi-section', 'style': 'margin-bottom:10px;' }, [
                    E('div', { 'class': 'cbi-section-actions' }, [
                        E('button', {
                            'class': 'btn cbi-button cbi-button-apply',
                            'click': ui.createHandlerFn(this, 'handleClearLog')
                        }, [ _('Clear Log') ]),
                        ' ',
                        E('button', {
                            'class': 'btn cbi-button cbi-button-edit',
                            'click': ui.createHandlerFn(this, 'handleReverseLog')
                        }, [ _('Reverse Order') ])
                    ])
                ]),
                
                // 日志显示区域
                E('div', { 'class': 'cbi-section' }, [
                    E('textarea', {
                        'id': 'log_content',
                        'class': 'cbi-input-textarea',
                        'style': 'width:100%; height:500px; font-family:monospace; font-size:12px; padding:10px; border-radius:4px;',
                        'readonly': 'readonly',
                        'wrap': 'off'
                    }, logContent || '')
                ])
            ])
        ]);
    },

    handle: function(ev) {
        var self = this;
        
        poll.add(function() {
            return fs.read('/etc/taskplan/taskplan.log').then(function(content) {
                var logArea = document.getElementById('log_content');
                if (logArea) {
                    if (self.reverse) {
                        logArea.value = content.split('\n').reverse().join('\n');
                    } else {
                        logArea.value = content;
                        logArea.scrollTop = logArea.scrollHeight;
                    }
                }
            });
        }, 5);
        
        return this.render.apply(this, arguments);
    }
});
