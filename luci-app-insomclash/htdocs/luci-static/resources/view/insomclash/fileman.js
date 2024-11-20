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
'require ui';
'require fs';
'require poll';

function loadScript(url) {
    return new Promise((resolve, reject) => {
        var script = document.createElement('script');
        script.onload = resolve;
        script.onerror = reject;
        script.src = url;
        document.head.appendChild(script);
    });
}

function loadStylesheet(url) {
    return new Promise((resolve, reject) => {
        var link = document.createElement('link');
        link.rel = 'stylesheet';
        link.onload = resolve;
        link.onerror = reject;
        link.href = url;
        document.head.appendChild(link);
    });
}

return view.extend({
    load: function() {
        return Promise.all([
            fs.exec('/usr/share/insomclash/fileman.sh', ['get']),
            fs.exec('/usr/share/insomclash/fileman.sh', ['list_proxy']),
            fs.exec('/usr/share/insomclash/fileman.sh', ['list_rule']),
            fs.exec('/usr/share/insomclash/fileman.sh', ['list_geo']),
            loadScript('/luci-static/resources/insomclash/assets/codemirror.min.js'),
            loadStylesheet('/luci-static/resources/insomclash/assets/codemirror.min.css'),
            loadStylesheet('/luci-static/resources/insomclash/assets/monokai.min.css')
        ]).then((data) => {
            return loadScript('/luci-static/resources/insomclash/assets/yaml.min.js').then(() => {
                return {
                    config: data[0].stdout ? data[0].stdout.trim() : '',
                    proxyList: data[1].stdout ? data[1].stdout.trim().split('\n').filter(Boolean) : [],
                    ruleList: data[2].stdout ? data[2].stdout.trim().split('\n').filter(Boolean) : [],
                    geoList: data[3].stdout ? data[3].stdout.trim().split('\n').filter(file => file.endsWith('.dat') || file.endsWith('.db') || file.endsWith('.mmdb')) : [],
                };
            });
        });
    },
    
    render: function(data) {
        var self = this;
        
        var storedNotification = localStorage.getItem('insomclashNotification');
        if (storedNotification) {
            var notification = JSON.parse(storedNotification);
            ui.addNotification(null, E('p', _(notification.message)), notification.type);
            localStorage.removeItem('insomclashNotification');
        }
        
        var tabContainer = E('div', { 'class': 'cbi-tabmenu' }, [
            E('ul', {}, [
                E('li', { 'class': 'cbi-tab', 'data-tab': 'config' },
                    E('a', { 'href': '#', 'click': ui.createHandlerFn(this, function() { self.switchTab('config'); }) }, _('CONFIG'))
                ),
                E('li', { 'class': 'cbi-tab-disabled', 'data-tab': 'proxy' },
                    E('a', { 'href': '#', 'click': ui.createHandlerFn(this, function() { self.switchTab('proxy'); }) }, _('PROXY'))
                ),
                E('li', { 'class': 'cbi-tab-disabled', 'data-tab': 'rule' },
                    E('a', { 'href': '#', 'click': ui.createHandlerFn(this, function() { self.switchTab('rule'); }) }, _('RULE'))
                ),
                E('li', { 'class': 'cbi-tab-disabled', 'data-tab': 'geo' },
                    E('a', { 'href': '#', 'click': ui.createHandlerFn(this, function() { self.switchTab('geo'); }) }, _('GEO'))
                )
            ])
        ]);

        var configEditor = E('div', { 'id': 'config-editor', 'class': 'cbi-section' }, [
            E('h3', {}, _('Config Editor')),
            E('div', { 'id': 'config-container', 'style': 'height: calc(100vh - 300px); min-height: 500px;' }),
            E('textarea', { 'id': 'config_content', 'style': 'display:none;' }, data.config),
            E('div', { 'class': 'cbi-section-node', 'style': 'margin-top: 20px;' }, [
                E('div', { 'class': 'cbi-value-field' }, [
                    E('button', {
                        'class': 'cbi-button cbi-button-save',
                        'click': ui.createHandlerFn(this, this.saveConfig)
                    }, _('Save Config'))
                ])
            ])
        ]);

        var proxyEditor = E('div', { 'id': 'proxy-editor', 'class': 'cbi-section', 'style': 'display: none;' }, [
            E('h3', {}, _('Proxy Editor')),
            E('div', { 'class': 'cbi-section-node' }, [
                E('div', { 'class': 'cbi-value' }, [
                    E('label', { 'class': 'cbi-value-title' }, _('Select Proxy')),
                    E('div', { 'class': 'cbi-value-field' }, [
                        E('select', {
                            'id': 'proxy-select',
                            'class': 'cbi-input-select',
                            'change': ui.createHandlerFn(this, this.loadProxyContent)
                        }, [
                            E('option', { 'value': '' }, _('Select a proxy')),
                            ... data.proxyList.map(proxy => E('option', { 'value': proxy }, proxy))
                        ])
                    ])
                ])
            ]),
            E('div', { 'id': 'proxy-container', 'style': 'height: calc(100vh - 350px); min-height: 500px;' }),
            E('div', { 'class': 'cbi-section-node', 'style': 'margin-top: 20px;' }, [
                E('div', { 'class': 'cbi-value-field' }, [
                    E('button', {
                        'class': 'cbi-button cbi-button-save',
                        'click': ui.createHandlerFn(this, this.saveProxy)
                    }, _('Save Proxy')),
                    E('input', {
                        'type': 'file',
                        'id': 'proxy-upload',
                        'style': 'display: none;',
                        'accept': '.yaml,.yml',
                        'change': ui.createHandlerFn(this, this.uploadProxy)
                    }),
                    E('button', {
                        'class': 'cbi-button cbi-button-apply',
                        'click': ui.createHandlerFn(this, function() {
                            document.getElementById('proxy-upload').click();
                        })
                    }, _('Upload Proxy'))
                ])
            ])
        ]);

        var ruleEditor = E('div', { 'id': 'rule-editor', 'class': 'cbi-section', 'style': 'display: none;' }, [
            E('h3', {}, _('Rule Manager')),
            E('div', { 'class': 'cbi-section-node' }, [
                E('div', { 'class': 'cbi-value' }, [
                    E('label', { 'class': 'cbi-value-title' }, _('Rule Files')),
                    E('div', { 'class': 'cbi-value-field' }, [
                        E('div', { 'class': 'file-list' }, data.ruleList.map(rule => 
                            E('div', { 'class': 'file-item' }, [
                                E('span', {}, rule),
                                E('button', {
                                    'class': 'cbi-button cbi-button-remove',
                                    'click': ui.createHandlerFn(this, function() {
                                        this.deleteFile('delete_rule', rule, 'Rule successfully deleted');
                                    })
                                }, _('Delete'))
                            ])
                        ))
                    ])
                ]),
                E('div', { 'class': 'cbi-value' }, [
                    E('label', { 'class': 'cbi-value-title' }, _('Upload Rule')),
                    E('div', { 'class': 'cbi-value-field' }, [
                        E('input', {
                            'type': 'file',
                            'id': 'rule-upload',
                            'accept': '.yaml,.yml',
                            'change': ui.createHandlerFn(this, this.uploadRule)
                        })
                    ])
                ])
            ])
        ]);

        var geoEditor = E('div', { 'id': 'geo-editor', 'class': 'cbi-section', 'style': 'display: none;' }, [
            E('h3', {}, _('GEO Manager')),
            E('div', { 'class': 'cbi-section-node' }, [
                E('div', { 'class': 'cbi-value' }, [
                    E('label', { 'class': 'cbi-value-title' }, _('GEO Files')),
                    E('div', { 'class': 'cbi-value-field' }, [
                        E('div', { 'class': 'file-list' }, data.geoList.map(geo => 
                            E('div', { 'class': 'file-item' }, [
                                E('span', {}, geo),
                                E('button', {
                                    'class': 'cbi-button cbi-button-remove',
                                    'click': ui.createHandlerFn(this, function() {
                                        this.deleteFile('delete_geo', geo, 'GEO successfully deleted');
                                    })
                                }, _('Delete'))
                            ])
                        ))
                    ])
                ]),
                E('div', { 'class': 'cbi-value' }, [
                    E('label', { 'class': 'cbi-value-title' }, _('Upload GEO')),
                    E('div', { 'class': 'cbi-value-field' }, [
                        E('input', {
                            'type': 'file',
                            'id': 'geo-upload',
                            'accept': '.dat,.db,.mmdb',
                            'change': ui.createHandlerFn(this, this.uploadGeo)
                        })
                    ])
                ])
            ])
        ]);

        var customStyle = E('style', {}, `
            .cbi-tabmenu li {
                display: inline-block;
                margin-right: 10px;
            }
            .cbi-tabmenu li a {
                padding: 8px 15px;
                text-decoration: none;
                border-radius: 5px 5px 0 0;
                transition: all 0.3s;
            }
            .cbi-tab a {
                background-color: #fa0202;
                color: #fff;
                font-weight: bold;
            }
            .cbi-tab-disabled a {
                background-color: #ddd;
                color: #020202;
                font-weight: bold;
            }
            .cbi-tab-disabled a:hover {
                background-color: #bbb;
            }
            
            .file-list {
                margin: 10px 0;
            }
            
            .file-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 8px;
                margin: 5px 0;
                background: #fff;
                border-radius: 4px;
            }
            
            .file-item span {
                color: #000000;
            }
            
            .cbi-button-remove {
                background-color: #fa0202;
                color: white;
                border: none;
                padding: 4px 12px;
                border-radius: 4px;
                cursor: pointer;
            }
            
            .cbi-button-remove:hover {
                background-color: #d60000;
            }
        `);

        return E('div', { 'class': 'cbi-map' }, [
            customStyle,
            E('h2', {}, _('Insomclash Config Editor')),
            tabContainer,
            configEditor,
            proxyEditor,
            ruleEditor,
            geoEditor,
            E('div', { 'style': 'text-align: center; padding: 10px; margin-top: 20px; font-style: italic;' }, [
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

    switchTab: function(tabName) {
        var tabs = ['config', 'proxy', 'rule', 'geo'];
        tabs.forEach(function(tab) {
            var element = document.getElementById(tab + '-editor');
            if (element) {
                element.style.display = (tab === tabName) ? 'block' : 'none';
            }
            var tabElement = document.querySelector('li[data-tab="' + tab + '"]');
            if (tabElement) {
                if (tab === tabName) {
                    tabElement.className = 'cbi-tab';
                } else {
                    tabElement.className = 'cbi-tab-disabled';
                }
            }
        });
        if (tabName === 'config' && this.configEditor) {
            this.configEditor.refresh();
        } else if (tabName === 'proxy' && this.proxyEditor) {
            this.proxyEditor.refresh();
        }
    },

    loadProxyContent: function(ev) {
        var proxyName = ev.target.value;
        if (proxyName) {
            fs.exec('/usr/share/insomclash/fileman.sh', ['get_proxy', proxyName])
                .then((res) => {
                    if (res.code === 0) {
                        this.proxyEditor.setValue(res.stdout);
                    } else {
                        ui.addNotification(null, E('p', {}, _('Error loading proxy content')));
                    }
                });
        }
    },

    saveConfig: function() {
        var content = this.configEditor.getValue();
        return fs.exec('/usr/share/insomclash/fileman.sh', ['set', content])
            .then((res) => {
                if (res.code === 0) {
                    ui.addNotification(null, E('p', {}, _('Config saved successfully')));
                } else {
                    ui.addNotification(null, E('p', {}, _('Error saving config')));
                }
            });
    },

    saveProxy: function() {
        var proxyName = document.getElementById('proxy-select').value;
        var content = this.proxyEditor.getValue();
        return fs.exec('/usr/share/insomclash/fileman.sh', ['set_proxy', proxyName, content])
            .then((res) => {
                if (res.code === 0) {
                    ui.addNotification(null, E('p', {}, _('Proxy saved successfully')));
                } else {
                    ui.addNotification(null, E('p', {}, _('Error saving proxy')));
                }
            });
    },

    uploadProxy: function(ev) {
        var file = ev.target.files[0];
        if (!file.name.endsWith('.yaml') && !file.name.endsWith('.yml')) {
            ui.addNotification(null, E('p', {}, _('Only YAML files are allowed')));
            return;
        }
        
        var reader = new FileReader();
        reader.onload = (e) => {
            var content = e.target.result;
            var fileName = file.name;
            
            console.log('Trying to upload file:', fileName);
            
            return fs.exec('/usr/share/insomclash/fileman.sh', ['upload_proxy', fileName, content])
                .then((res) => {
                    console.log('Respons dari server:', res);
                    if (res.code === 0) {
                        ui.addNotification(null, E('p', {}, _('Proxy uploaded successfully')));
                        this.load().then(this.render);
                    } else {
                        ui.addNotification(null, E('p', {}, _('Failed to upload proxy: ') + res.stderr));
                    }
                })
                .catch((error) => {
                    console.error('Error saat mengunggah:', error);
                    ui.addNotification(null, E('p', {}, _('An error occurred while uploading proxy')));
                });
        };
        reader.readAsText(file);
    },

    uploadRule: function(ev) {
        var file = ev.target.files[0];
        if (!file.name.endsWith('.yaml') && !file.name.endsWith('.yml')) {
            ui.addNotification(null, E('p', {}, _('Only YAML files are allowed for rules')));
            return;
        }
        this.uploadFile(file, 'upload_rule');
    },

    uploadGeo: function(ev) {
        var file = ev.target.files[0];
        if (!file.name.endsWith('.dat') && !file.name.endsWith('.db') && !file.name.endsWith('.mmdb')) {
            ui.addNotification(null, E('p', {}, _('Only DAT, DB, and MMDB files are allowed for GEO')));
            return;
        }
        this.uploadFile(file, 'upload_geo');
    },

    uploadFile: function(file, action) {
        var reader = new FileReader();
        reader.onload = (e) => {
            var content = e.target.result;
            var fileName = file.name;
            
            console.log('Trying to upload file:', fileName);
            
            return fs.exec('/usr/share/insomclash/fileman.sh', [action, fileName, content])
                .then((res) => {
                    console.log('Respons dari server:', res);
                    if (res.code === 0) {
                        ui.addNotification(null, E('p', {}, _('File uploaded successfully')));
                        this.load().then(this.render);
                    } else {
                        ui.addNotification(null, E('p', {}, _('Failed to upload file: ') + res.stderr));
                    }
                })
                .catch((error) => {
                    console.error('Error saat mengunggah:', error);
                    ui.addNotification(null, E('p', {}, _('An error occurred while uploading file')));
                });
        };
        reader.readAsText(file);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null,

    addFooter: function() {
        var self = this;
        setTimeout(function() {
            if (typeof CodeMirror !== 'undefined') {
                var configContent = document.getElementById('config_content');
                console.log('Config content:', configContent ? configContent.value : 'Not found');
                self.configEditor = CodeMirror(document.getElementById('config-container'), {
                    value: configContent ? configContent.value : '',
                    lineNumbers: true,
                    mode: 'yaml',
                    theme: 'monokai',
                    viewportMargin: Infinity
                });
                self.configEditor.setSize('100%', '100%');
                self.configEditor.refresh();
                console.log('CodeMirror initialized');
                
                self.proxyEditor = CodeMirror(document.getElementById('proxy-container'), {
                    lineNumbers: true,
                    mode: 'yaml',
                    theme: 'monokai',
                    viewportMargin: Infinity
                });
                self.proxyEditor.setSize('100%', '100%');
            } else {
                console.error('CodeMirror not defined');
                ui.addNotification(null, E('p', {}, _('Error: CodeMirror could not be loaded')));
            }
        }, 100);
    },

    deleteFile: function(action, filename, successMessage) {
        return fs.exec('/usr/share/insomclash/fileman.sh', [action, filename])
            .then((res) => {
                if (res.code === 0) {
                    localStorage.setItem('insomclashNotification', JSON.stringify({
                        type: 'normal',
                        message: successMessage
                    }));
                    window.location.reload();
                } else {
                    ui.addNotification(null, E('p', {}, _('Failed to delete file: ') + res.stderr));
                }
            })
            .catch((error) => {
                console.error('Error saat menghapus:', error);
                ui.addNotification(null, E('p', {}, _('An error occurred while deleting file')));
            });
    }
});
