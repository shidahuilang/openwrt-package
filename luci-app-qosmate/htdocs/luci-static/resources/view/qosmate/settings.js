'use strict';
'require view';
'require form';
'require ui';
'require uci';
'require rpc';
'require fs';
'require poll';
'require tools.widgets as widgets';

const UI_VERSION = '1.0.7';

var callInitAction = rpc.declare({
    object: 'luci',
    method: 'setInitAction',
    params: ['name', 'action'],
    expect: { result: false }
});

var currentVersion = 'Unknown';
var latestVersion = 'Unknown';

function fetchCurrentVersion() {
    return fs.read('/etc/qosmate.sh').then(function(content) {
        var match = content.match(/^VERSION="(.+)"/m);
        currentVersion = match ? match[1] : 'Unknown';
        return currentVersion;
    }).catch(function(error) {
        console.error('Error reading current version:', error);
        return 'Unknown';
    });
}

function fetchLatestVersion() {
    return new Promise((resolve) => {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'https://raw.githubusercontent.com/hudra0/qosmate/main/etc/qosmate.sh', true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                var match = xhr.responseText.match(/^VERSION="(.+)"/m);
                latestVersion = match ? match[1] : 'Unable to fetch';
            } else {
                latestVersion = 'Unable to fetch';
            }
            resolve(latestVersion);
        };
        xhr.onerror = function() {
            latestVersion = 'Unable to fetch';
            resolve(latestVersion);
        };
        xhr.timeout = 2000; // 2 second timeout
        xhr.ontimeout = function() {
            latestVersion = 'Unable to fetch';
            resolve(latestVersion);
        };
        xhr.send();
    });
}

return view.extend({
    handleSaveApply: function(ev) {
        return this.handleSave(ev)
            .then(() => ui.changes.apply())
            .then(() => uci.load('qosmate'))
            .then(() => uci.get_first('qosmate', 'global', 'enabled'))
            .then(enabled => {
                if (enabled === '0') {
                    return fs.exec_direct('/etc/init.d/qosmate', ['stop']);
                } else {
                    return fs.exec_direct('/etc/init.d/qosmate', ['restart']);
                }
            })
            .then(() => {
                ui.hideModal();
                window.location.reload();
            })
            .catch(err => {
                ui.hideModal();
                ui.addNotification(null, E('p', _('Failed to save settings or update QoSmate service: ') + err.message));
            });
    },

    load: function() {
        return Promise.all([
            uci.load('qosmate'),
            fetchCurrentVersion().catch(() => 'Unable to fetch'),
            fetchLatestVersion()
        ]).catch(error => {
            console.error('Error in load function:', error);
            return [null, 'Unable to fetch', 'Unable to fetch'];
        });
    },

    render: function() {
        var m, s, o;

        m = new form.Map('qosmate', _('QoSmate Settings'), _('Configure QoSmate settings.'));

        s = m.section(form.NamedSection, 'global', 'global', _('Global Settings'));
        s.anonymous = true;

        o = s.option(form.DummyValue, '_status', _('Service Status'));
        o.rawhtml = true;
        o.render = function(section_id) {
            var runningText = _('Running');
            var stoppedText = _('Stopped');
            var status = uci.get('qosmate', 'global', 'enabled') === '1' ? runningText : stoppedText;
            var statusColor = status === runningText ? 'green' : 'red';
            return E('div', { 'class': 'cbi-value' }, [
                E('label', { 'class': 'cbi-value-title' }, _('Service Status')),
                E('div', { 'class': 'cbi-value-field', 'style': 'color:' + statusColor }, status)
            ]);
        };
        
        o = s.option(form.DummyValue, '_buttons', _('Service Control'));
        o.rawhtml = true;
        o.render = function(section_id) {
            var buttonStyle = 'button cbi-button';
            return E('div', { 'class': 'cbi-value' }, [
                E('label', { 'class': 'cbi-value-title' }, _('Service Control')),
                E('div', { 'class': 'cbi-value-field' }, [
                    E('button', {
                        'class': buttonStyle + ' cbi-button-apply',
                        'click': ui.createHandlerFn(this, function() {
                            return fs.exec_direct('/etc/init.d/qosmate', ['start'])
                                .then(function() {
                                    ui.addNotification(null, E('p', _('QoSmate started')), 'success');
                                    window.setTimeout(function() { location.reload(); }, 1000);
                                })
                                .catch(function(e) { ui.addNotification(null, E('p', _('Failed to start QoSmate: ') + e), 'error'); });
                        })
                    }, _('Start')),
                    ' ',
                    E('button', {
                        'class': buttonStyle + ' cbi-button-neutral',
                        'click': ui.createHandlerFn(this, function() {
                            return fs.exec_direct('/etc/init.d/qosmate', ['restart'])
                                .then(function() {
                                    ui.addNotification(null, E('p', _('QoSmate restarted')), 'success');
                                    window.setTimeout(function() { location.reload(); }, 1000);
                                })
                                .catch(function(e) { ui.addNotification(null, E('p', _('Failed to restart QoSmate: ') + e), 'error'); });
                        })
                    }, _('Restart')),
                    ' ',
                    E('button', {
                        'class': buttonStyle + ' cbi-button-reset',
                        'click': ui.createHandlerFn(this, function() {
                            return fs.exec_direct('/etc/init.d/qosmate', ['stop'])
                                .then(function() {
                                    ui.addNotification(null, E('p', _('QoSmate stopped')), 'success');
                                    window.setTimeout(function() { location.reload(); }, 1000);
                                })
                                .catch(function(e) { ui.addNotification(null, E('p', _('Failed to stop QoSmate: ') + e), 'error'); });
                        })
                    }, _('Stop'))
                ])
            ]);
        };

        // Auto Setup Button
        o = s.option(form.Button, '_auto_setup', _('Auto Setup'));
        o.inputstyle = 'apply';
        o.inputtitle = _('Start Auto Setup');
        o.onclick = ui.createHandlerFn(this, function() {
            ui.showModal(_('Auto Setup'), [
                E('p', _('This will run a speed test and configure QoSmate automatically.')),
                E('div', { 'class': 'cbi-value' }, [
                    E('label', { 'class': 'cbi-value-title' }, _('Gaming Device IP (optional)')),
                    E('input', { 'id': 'gaming_ip', 'type': 'text', 'class': 'cbi-input-text' })
                ]),
                E('div', { 'class': 'right' }, [
                    E('button', {
                        'class': 'btn',
                        'click': ui.hideModal
                    }, _('Cancel')),
                    ' ',
                    E('button', {
                        'class': 'btn cbi-button-action',
                        'click': ui.createHandlerFn(this, function() {
                            var gamingIp = document.getElementById('gaming_ip').value;
                            ui.showModal(_('Running Auto Setup'), [
                                E('p', { 'class': 'spinning' }, _('Please wait while the auto setup is in progress...')),
                                E('div', { 'style': 'margin-top: 1em; border-top: 1px solid #ccc; padding-top: 1em;' }, [
                                    E('p', { 'style': 'font-weight: bold;' }, _('Note:')),
                                    E('p', _('Router-based speed tests may underestimate actual speeds. These results serve as a starting point and may require manual adjustment for optimal performance.'))
                                ])
                            ]);
                            return fs.exec_direct('/etc/init.d/qosmate', ['auto_setup_noninteractive', gamingIp])
                                .then(function(res) {
                                    var outputFile = res.trim();
                                    return fs.read(outputFile).then(function(output) {
                                        ui.hideModal();
                                        
                                        var wanInterface = output.match(/Detected WAN interface: (.+)/);
                                        var downloadSpeed = output.match(/Download speed: (.+) Mbit\/s/);
                                        var uploadSpeed = output.match(/Upload speed: (.+) Mbit\/s/);
                                        var downrate = output.match(/DOWNRATE: (.+) kbps/);
                                        var uprate = output.match(/UPRATE: (.+) kbps/);

                                        if (!downloadSpeed || !uploadSpeed || parseFloat(downloadSpeed[1]) <= 0 || parseFloat(uploadSpeed[1]) <= 0 ||
                                        !downrate || !uprate || parseInt(downrate[1]) <= 0 || parseInt(uprate[1]) <= 0) {
                                        ui.addNotification(null, E('p', _('Invalid speed test results. Please try again or set values manually.')), 'error');
                                        return;
                                        }                                        
                                        var gamingRules = output.match(/Gaming device rules added for IP: (.+)/);
        
                                        ui.showModal(_(''), [
                                            E('h2', { 'style': 'text-align:center; margin-bottom: 1em;' }, _('Auto Setup Results')),
                                            E('h3', { 'style': 'margin-bottom: 0.5em;' }, _('Speed Test Results')),
                                            E('p', { 'style': 'color: orange; margin-bottom: 1em;' }, _('Note: Router-based speed tests may underestimate actual speeds. For best results, consider running tests from a LAN device and manually entering the values. These results serve as a starting point.')),
                                            E('div', { 'style': 'display: table; width: 100%;' }, [
                                                E('div', { 'style': 'display: table-row;' }, [
                                                    E('div', { 'style': 'display: table-cell; padding: 5px; font-weight: bold;' }, _('WAN Interface')),
                                                    E('div', { 'style': 'display: table-cell; padding: 5px;' }, wanInterface ? wanInterface[1] : _('Not detected'))
                                                ]),
                                                E('div', { 'style': 'display: table-row;' }, [
                                                    E('div', { 'style': 'display: table-cell; padding: 5px; font-weight: bold;' }, _('Download Speed')),
                                                    E('div', { 'style': 'display: table-cell; padding: 5px;' }, downloadSpeed ? downloadSpeed[1] + ' Mbit/s' : _('Not available'))
                                                ]),
                                                E('div', { 'style': 'display: table-row;' }, [
                                                    E('div', { 'style': 'display: table-cell; padding: 5px; font-weight: bold;' }, _('Upload Speed')),
                                                    E('div', { 'style': 'display: table-cell; padding: 5px;' }, uploadSpeed ? uploadSpeed[1] + ' Mbit/s' : _('Not available'))
                                                ])
                                            ]),
                                            E('h3', { 'style': 'margin-top: 1em; margin-bottom: 0.5em;' }, _('QoS Configuration')),
                                            E('div', { 'style': 'display: table; width: 100%;' }, [
                                                E('div', { 'style': 'display: table-row;' }, [
                                                    E('div', { 'style': 'display: table-cell; padding: 5px; font-weight: bold;' }, _('Download Rate')),
                                                    E('div', { 'style': 'display: table-cell; padding: 5px;' }, downrate ? downrate[1] + ' kbps' : _('Not set'))
                                                ]),
                                                E('div', { 'style': 'display: table-row;' }, [
                                                    E('div', { 'style': 'display: table-cell; padding: 5px; font-weight: bold;' }, _('Upload Rate')),
                                                    E('div', { 'style': 'display: table-cell; padding: 5px;' }, uprate ? uprate[1] + ' kbps' : _('Not set'))
                                                ])
                                            ]),
                                            gamingRules ? E('div', { 'style': 'margin-top: 1em;' }, [
                                                E('div', { 'style': 'font-weight: bold;' }, _('Gaming Rules')),
                                                E('div', {}, _('Added for IP: ') + gamingRules[1])
                                            ]) : '',
                                            E('div', { 'class': 'right', 'style': 'margin-top: 1em;' }, [
                                                E('button', {
                                                    'class': 'btn cbi-button-action',
                                                    'click': ui.createHandlerFn(this, function() {
                                                        ui.showModal(_('Applying Changes'), [
                                                            E('p', { 'class': 'spinning' }, _('Please wait while the changes are being applied...'))
                                                        ]);
                                                        
                                                        var rootQdisc = uci.get('qosmate', 'settings', 'ROOT_QDISC');
                                                        var downrateValue = downrate ? parseInt(downrate[1]) : 0;
                                                        var uprateValue = uprate ? parseInt(uprate[1]) : 0;
                                                        
                                                        if (rootQdisc === 'hfsc' && (downrateValue <= 0 || uprateValue <= 0)) {
                                                            ui.hideModal();
                                                            ui.addNotification(null, E('p', _('Invalid rates for HFSC. Please set non-zero values manually.')), 'error');
                                                        } else {
                                                            uci.set('qosmate', 'settings', 'DOWNRATE', downrateValue.toString());
                                                            uci.set('qosmate', 'settings', 'UPRATE', uprateValue.toString());
                                                            
                                                            uci.save()
                                                            .then(() => {
                                                                return fs.exec_direct('/etc/init.d/qosmate', ['restart']);
                                                            })
                                                            .then(() => {
                                                                ui.hideModal();
                                                                ui.addNotification(null, E('p', _('QoSmate settings updated and service restarted.')), 'success');
                                                                window.setTimeout(function() {
                                                                    location.reload();
                                                                }, 2000);
                                                            })
                                                            .catch(function(err) {
                                                                ui.hideModal();
                                                                ui.addNotification(null, E('p', _('Failed to update settings or restart QoSmate: ') + err), 'error');
                                                            });
                                                        }
                                                    })
                                                }, _('Apply and Reload'))
                                            ])
                                        ]);
                                    });
                                })
                                .catch(function(err) {
                                    ui.hideModal();
                                    ui.addNotification(null, E('p', _('Auto setup failed: ') + err), 'error');
                                });
                        })
                    }, _('Start'))
                ])
            ]);
        });

        // Version information
        o = s.option(form.DummyValue, '_version', _('Version Information'));
        o.rawhtml = true;
        o.render = function(section_id) {
            var updateAvailable = currentVersion !== latestVersion && 
                                currentVersion !== _('Unable to fetch') && 
                                latestVersion !== _('Unable to fetch');

            var html = '<div>' +
                    '<strong>' + _('Current Version') + ':</strong> ' + currentVersion + '<br>' +
                    '<strong>' + _('Latest Version') + ':</strong> ' + latestVersion + '<br>';

            if (updateAvailable) {
                html += '<br><span style="color: red;">' + _('A new version is available!') + '</span><br>';
            } else if (currentVersion !== 'Unable to fetch' && latestVersion !== 'Unable to fetch') {
                html += '<br><span style="color: green;">' + _('QoSmate is up to date.') + '</span>';
            } else {
                html += '<br><span style="color: orange;">' + _('Unable to check for updates.') + '</span>';
            }

            html += '</div>';

            return E('div', { 'class': 'cbi-value' }, [
                E('label', { 'class': 'cbi-value-title' }, _('Version Information')),
                E('div', { 'class': 'cbi-value-field' }, html)
            ]);
        };

        s = m.section(form.NamedSection, 'settings', 'settings', _('Basic Settings'));
        s.anonymous = true;
        
        function createOption(name, title, description, placeholder, datatype) {
            var opt = s.option(form.Value, name, title, description);
            opt.datatype = datatype || 'string';
            opt.rmempty = true;
            opt.placeholder = placeholder;
            
            if (datatype === 'uinteger') {
                opt.validate = function(section_id, value) {
                    if (value === '' || value === null) return true;
                    if (!/^\d+$/.test(value)) return _('Must be a non-negative integer or empty');
                    var intValue = parseInt(value, 10);
                    var rootQdisc = this.section.formvalue(section_id, 'ROOT_QDISC');
                    if (intValue === 0 && rootQdisc === 'hfsc') {
                        return _('Value must be greater than 0 for HFSC');
                    }
                    return true;
                };
            }
            return opt;
        }
        
        var wanInterface = uci.get('qosmate', 'settings', 'WAN') || ''; // Get the current WAN interface from config
        o = s.option(widgets.DeviceSelect, 'WAN', _('WAN Interface'), _('Select the WAN interface'));
        o.rmempty = false;
        o.editable = true; // Allow manual entry
        o.default = wanInterface;

        createOption('DOWNRATE', _('Download Rate (kbps)'), _('Set the download rate in kbps'), _('Default: 90000'), 'uinteger');
        createOption('UPRATE', _('Upload Rate (kbps)'), _('Set the upload rate in kbps'), _('Default: 45000'), 'uinteger');
        
        o = s.option(form.ListValue, 'ROOT_QDISC', _('Root Queueing Discipline'), _('Select the root queueing discipline'));
        o.value('hfsc', _('HFSC'));
        o.value('cake', _('CAKE'));
        o.default = 'hfsc';
        o.onchange = function(ev, section_id, value) {
            var downrate = this.map.lookupOption('DOWNRATE', section_id)[0];
            var uprate = this.map.lookupOption('UPRATE', section_id)[0];
            if (downrate && uprate) {
                downrate.map.checkDepends();
                uprate.map.checkDepends();
            }
        };
        
        return m.render();
    }
});

// Poll for current and latest version every 30 seconds
poll.add(function() {
    return Promise.all([
        fetchCurrentVersion(),
        fetchLatestVersion()
    ]);
}, 30);

function updateQosmate() {
    // Implement the update logic here
    ui.showModal(_('Updating QoSmate'), [
        E('p', { 'class': 'spinning' }, _('Updating QoSmate. Please wait...'))
    ]);

    // Simulating an update process
    setTimeout(function() {
        ui.hideModal();
        window.location.reload();
    }, 5000);
}
