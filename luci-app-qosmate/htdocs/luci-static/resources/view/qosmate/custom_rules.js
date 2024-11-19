'use strict';
'require view';
'require form';
'require ui';
'require uci';
'require fs';
'require rpc';

var callInitAction = rpc.declare({
    object: 'luci',
    method: 'setInitAction',
    params: ['name', 'action'],
    expect: { result: false }
});

return view.extend({
    handleSaveApply: function(ev) {
        return this.handleSave(ev)
            .then(() => {
                return ui.changes.apply();
            })
            .then(() => {
                return callInitAction('qosmate', 'restart');
            })
            .then(() => {
                ui.addNotification(null, E('p', _('Custom rules have been saved and applied.')), 'success');
            })
            .catch((err) => {
                ui.addNotification(null, E('p', _('Failed to save settings or restart QoSmate: ') + err.message), 'error');
            });
    },

    load: function() {
        return Promise.all([
            fs.read('/etc/qosmate.d/custom_rules.nft')
                .then(content => {
                    content = content.replace(/^table\s+inet\s+qosmate_custom\s*{/, '');
                    content = content.replace(/}\s*$/, '');
                    return content.trim();
                })
                .catch(() => ''),
            fs.read('/tmp/qosmate_custom_rules_validation.txt')
                .catch(() => '')
        ]);
    },

    render: function([customRules, validationResult]) {
        var m, s, o;

        m = new form.Map('qosmate', _('QoSmate Custom Rules'),
            _('Define custom nftables rules for advanced traffic control.'));

        s = m.section(form.NamedSection, 'custom_rules', 'qosmate', _('Custom Rules'));
        s.anonymous = true;
        s.addremove = false;

        o = s.option(form.Button, '_erase', _('Erase Rules'));
        o.inputstyle = 'remove';
        o.inputtitle = _('Erase Custom Rules');
        o.onclick = function(ev) {
            return ui.showModal(_('Erase Custom Rules'), [
                E('p', _('Are you sure you want to erase all custom rules? This action cannot be undone.')),
                E('div', { 'class': 'right' }, [
                    E('button', {
                        'class': 'btn',
                        'click': ui.hideModal
                    }, _('Cancel')),
                    ' ',
                    E('button', {
                        'class': 'btn cbi-button-negative',
                        'click': ui.createHandlerFn(this, function() {
                            var textarea = document.querySelector('textarea[name="cbid.qosmate.custom_rules.custom_rules"]');
                            if (textarea) {
                                textarea.value = '';
                            }
                            
                            return fs.remove('/etc/qosmate.d/custom_rules.nft')
                                .then(() => {
                                    return ui.changes.apply();
                                })
                                .then(() => {
                                    return callInitAction('qosmate', 'restart');
                                })
                                .then(() => {
                                    ui.hideModal();
                                    ui.addNotification(null, E('p', _('Custom rules have been erased and changes applied.')), 'success');
                                    window.setTimeout(function() {
                                        window.location.reload();
                                    }, 2000);
                                })
                                .catch((err) => {
                                    ui.hideModal();
                                    ui.addNotification(null, E('p', _('Failed to erase custom rules or apply changes: ') + err.message), 'error');
                                });
                        })
                    }, _('Erase'))
                ])
            ]);
        };

        o = s.option(form.TextValue, 'custom_rules', _('Custom nftables Rules'));
        o.rows = 20;
        o.wrap = 'off';
        o.rmempty = true;
        o.monospace = true;
        o.datatype = 'string';
        o.description = _('Enter your custom nftables rules here. The "table inet qosmate_custom { ... }" wrapper will be added automatically.');
        o.load = function(section_id) {
            return customRules;
        };
        o.write = function(section_id, formvalue) {
            const fullContent = `table inet qosmate_custom {
${formvalue.trim()}
}`;
            return fs.write('/etc/qosmate.d/custom_rules.nft', fullContent)
                .then(() => {
                    return fs.exec('/etc/init.d/qosmate', ['validate_custom_rules']);
                })
                .then(() => {
                    return fs.read('/tmp/qosmate_custom_rules_validation.txt');
                })
                .then((result) => {
                    if (result.includes('Custom rules validation successful.')) {
                        ui.addNotification(null, E('p', _('Custom rules validation successful.')), 'success');
                    } else {
                        ui.addNotification(null, E('p', _('Custom rules validation failed. Please check the validation result below.')), 'warning');
                    }
                });
        };

        o = s.option(form.DummyValue, '_validation_result', _('Validation Result'));
        o.rawhtml = true;
        o.default = validationResult
            ? E('div', { 'class': 'cbi-value-field' },
                E('div', { 'class': 'cbi-section-node', 'style': 'background-color:#f9f9f9; border:1px solid #e5e5e5; border-radius:3px; padding:10px; margin-top:5px; min-width: 700px' },
                    E('pre', { 'style': 'white-space:pre-wrap; word-break:break-word;' }, validationResult)
                )
            )
            : _('No validation performed yet');

        o = s.option(form.Button, '_validate', _('Validate Rules'));
        o.inputstyle = 'apply';
        o.inputtitle = _('Validate');
        o.onclick = function(ev) {
            var map = this.map;
            var section_id = 'custom_rules'; // Assuming this is the correct section_id
        
            var customRulesTextarea = document.getElementById('widget.cbid.qosmate.' + section_id + '.custom_rules');
            if (!customRulesTextarea) {
                ui.addNotification(null, E('p', _('Error: Could not find custom rules textarea')), 'error');
                return;
            }
        
            var currentRules = customRulesTextarea.value;
            var fullContent = `table inet qosmate_custom {\n${currentRules.trim()}\n}`;
        
            ui.showModal(_('Validating Rules'), [
                E('p', { 'class': 'spinning' }, _('Please wait while the rules are being validated...'))
            ]);
        
            return fs.write('/etc/qosmate.d/custom_rules.nft', fullContent)
                .then(() => {
                    return fs.exec('/etc/init.d/qosmate', ['validate_custom_rules']);
                })
                .then(() => {
                    return fs.read('/tmp/qosmate_custom_rules_validation.txt');
                })
                .then((result) => {
                    ui.hideModal();
                    if (result.includes('Custom rules validation successful.')) {
                        ui.addNotification(null, E('p', _('Custom rules validation successful.')), 'success');
                    } else {
                        ui.addNotification(null, E('p', _('Custom rules validation failed. Please check the validation result below.')), 'warning');
                    }
                    var validationResultElement = document.getElementById('cbid.qosmate.custom_rules._validation_result');
                    if (validationResultElement) {
                        validationResultElement.innerHTML = E('pre', {}, result).outerHTML;
                    }
                    ui.showModal(_('Finalizing Validation'), [
                        E('p', { 'class': 'spinning' }, _('Finalizing validation results, please wait...'))
                    ]);
                    
                    setTimeout(function() {
                        window.location.reload();
                    }, 2000);
                })
                .catch((err) => {
                    ui.hideModal();
                    ui.addNotification(null, E('p', _('Error during validation: ') + err), 'error');
                    
                    ui.showModal(_('Finalizing Validation'), [
                        E('p', { 'class': 'spinning' }, _('Finalizing validation results, please wait...'))
                    ]);
                    
                    setTimeout(function() {
                        window.location.reload();
                    }, 2000);
                });
            };

            o = s.option(form.DummyValue, '_rules_info', _('Rules Information'));
            o.rawhtml = true;
            o.default = '<div class="cbi-value-description" style="background-color:#f9f9f9; border:1px solid #e5e5e5; border-radius:3px; padding:15px; margin-top:10px; margin-bottom:10px; width: 700px;">' +
                '<p>' + _('Example rules:') + '</p>' +
                '<pre style="border:1px solid #ddd; padding:10px; background-color:#fff; border-radius:3px; white-space:pre-wrap; word-break:break-word; overflow-x:auto;">' +
                'chain ingress {\n' +
                '    type filter hook ingress device eth1 priority -500; policy accept;\n' +
                '    iif eth1 counter ip dscp set cs0 comment "Wash all ISP DSCP marks to CS0 (IPv4)"\n' +
                '    iif eth1 counter ip6 dscp set cs0 comment "Wash all ISP DSCP marks to CS0 (IPv6)"\n' +
                '}\n\n' +
                'chain forward {\n' +
                '    type filter hook forward priority 0; policy accept;\n' +
                '    # Limit and mark high-rate TCP traffic from specific IP\n' +
                '    ip saddr 192.168.138.100 tcp flags & (fin|syn|rst|ack) != 0\n' +
                '    limit rate over 300/second burst 300 packets\n' +
                '    counter ip dscp set cs1\n' +
                '    comment "Mark TCP traffic from 192.168.138.100 exceeding 300 pps as CS1"\n' +
                '}\n' +
                '</pre>' +
                '<p style="margin-top:10px;"><strong>' + _('Warning:') + '</strong> ' + _('Incorrect rules can disrupt network functionality. Use with caution.') + '</p>' +
                '</div>';

        return m.render();
    }
});
