'use strict';
'require view';
'require ui';
'require uci';
'require form';
'require rpc';
'require fs';
'require tools.widgets as widgets';

var callInitAction = rpc.declare({
    object: 'luci',
    method: 'setInitAction',
    params: ['name', 'action'],
    expect: { result: false }
});

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

    render: function() {
        var m, s, o;

        m = new form.Map('qosmate', _('QoSmate Rules'),
            _('Configure QoS rules for marking packets with DSCP values.'));

        s = m.section(form.GridSection, 'rule', _('Rules'));
        s.addremove = true;
        s.anonymous = true;
        s.sortable  = true;

        s.tab('general', _('General Settings'));
        s.tab('mapping', _('DSCP Mapping'));

        // Add mapping information to the description
        s.description = E('div', { 'class': 'cbi-section-descr' }, [
            E('h4', _('HFSC Mapping:')),
            E('table', { 'class': 'table' }, [
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left', 'width': '50%' }, _('High Priority [Realtime] (1:11)')),
                    E('td', { 'class': 'td left' }, 'EF, CS5, CS6, CS7')
                ]),
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, _('Fast Non-Realtime (1:12)')),
                    E('td', { 'class': 'td left' }, 'CS4, AF41, AF42')
                ]),
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, _('Normal (1:13)')),
                    E('td', { 'class': 'td left' }, 'CS0')
                ]),
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, _('Low Priority (1:14)')),
                    E('td', { 'class': 'td left' }, 'CS2')
                ]),
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, _('Bulk (1:15)')),
                    E('td', { 'class': 'td left' }, 'CS1')
                ])
            ]),
            E('h4', _('CAKE Mapping (diffserv4):')),
            E('table', { 'class': 'table' }, [
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left', 'width': '50%' }, _('Voice (Highest Priority)')),
                    E('td', { 'class': 'td left' }, 'CS7, CS6, EF, VA, CS5, CS4')
                ]),
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, _('Video')),
                    E('td', { 'class': 'td left' }, 'CS3, AF4x, AF3x, CS2, TOS1')
                ]),
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, _('Best Effort')),
                    E('td', { 'class': 'td left' }, 'CS0, AF1x, AF2x, TOS0')
                ]),
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, _('Bulk (Lowest Priority)')),
                    E('td', { 'class': 'td left' }, 'CS1, LE')
                ])
            ])
        ]);

        o = s.taboption('general', form.Value, 'name', _('Name'));
        o.rmempty = false;

        o = s.option(form.DummyValue, 'proto', _('Protocol'));
        o.cfgvalue = function(section_id) {
            var proto = uci.get('qosmate', section_id, 'proto');
            if (Array.isArray(proto)) {
                return proto.map(function(p) { return p.toUpperCase(); }).join(', ');
            } else if (typeof proto === 'string') {
                return proto.toUpperCase();
            }
            return _('Any');
        };
              
        o = s.taboption('general', form.MultiValue, 'proto', _('Protocol'));
        o.value('tcp', _('TCP'));
        o.value('udp', _('UDP'));
        o.value('icmp', _('ICMP'));
        o.rmempty = true;
        o.default = 'tcp udp';
        o.modalonly = true;
        
        o.cfgvalue = function(section_id) {
            var value = uci.get('qosmate', section_id, 'proto');
            if (Array.isArray(value)) {
                return value;
            } else if (typeof value === 'string') {
                return value.split(/\s+/);
            }
            return [];
        };
        
        o.write = function(section_id, value) {
            if (value && value.length) {
                uci.set('qosmate', section_id, 'proto', value.join(' '));
            } else {
                uci.unset('qosmate', section_id, 'proto');
            }
        };
        
        o.validate = function(section_id, value) {
            if (!value || value.length === 0) {
                return true;
            }
            
            var valid = ['tcp', 'udp', 'icmp'];
            var toValidate = Array.isArray(value) ? value : value.split(/\s+/);
            
            for (var i = 0; i < toValidate.length; i++) {
                if (valid.indexOf(toValidate[i]) === -1) {
                    return _('Invalid protocol: %s').format(toValidate[i]);
                }
            }
            return true;
        };
        
        o.remove = function(section_id) {
            uci.unset('qosmate', section_id, 'proto');
        };

        o = s.taboption('general', form.DynamicList, 'src_ip', _('Source IP'));
        o.datatype = 'or(ip4addr, ip6addr, string)';
        o.placeholder = _('any');
        o.rmempty = true;
        o.write = function(section_id, formvalue) {
            var values = formvalue.map(function(v) {
                return v.replace(/^!(?!=)/, '!=');
            });
            return this.super('write', [section_id, values]);
        };
        o.validate = function(section_id, value) {
            if (value === '')
                return true;
            
            if (!value.match(/^(!|!=)?((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2})?)|([0-9a-fA-F:]{2,}(::)?[0-9a-fA-F:]*(%\w+)?(\/\d{1,3})?)|[a-zA-Z0-9_]+)$/))
                return _('Invalid IP address or hostname');
            return true;
        };
        
        o = s.taboption('general', form.DynamicList, 'src_port', _('Source port'));
        o.datatype = 'or(port, portrange, string)';
        o.placeholder = _('any');
        o.rmempty = true;
        o.write = function(section_id, formvalue) {
            var values = formvalue.map(function(v) {
                return v.replace(/^!(?!=)/, '!=');
            });
            return this.super('write', [section_id, values]);
        };
        o.validate = function(section_id, value) {
            if (value === '')
                return true;
            
            if (!value.match(/^(!|!=)?(\d+(-\d+)?|[a-zA-Z0-9]+)$/))
                return _('Invalid port or port range');
            return true;
        };
        
        o = s.taboption('general', form.DynamicList, 'dest_ip', _('Destination IP'));
        o.datatype = 'or(ip4addr, ip6addr, string)';
        o.placeholder = _('any');
        o.rmempty = true;
        o.write = function(section_id, formvalue) {
            var values = formvalue.map(function(v) {
                return v.replace(/^!(?!=)/, '!=');
            });
            return this.super('write', [section_id, values]);
        };
        o.validate = function(section_id, value) {
            if (value === '')
                return true;
            
            if (!value.match(/^(!|!=)?((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2})?)|([0-9a-fA-F:]{2,}(::)?[0-9a-fA-F:]*(%\w+)?(\/\d{1,3})?)|[a-zA-Z0-9_]+)$/))
                return _('Invalid IP address or hostname');
            return true;
        };
        
        o = s.taboption('general', form.DynamicList, 'dest_port', _('Destination port'));
        o.datatype = 'or(port, portrange, string)';
        o.placeholder = _('any');
        o.rmempty = true;
        o.write = function(section_id, formvalue) {
            var values = formvalue.map(function(v) {
                return v.replace(/^!(?!=)/, '!=');
            });
            return this.super('write', [section_id, values]);
        };
        o.validate = function(section_id, value) {
            if (value === '')
                return true;
            
            if (!value.match(/^(!|!=)?(\d+(-\d+)?|[a-zA-Z0-9]+)$/))
                return _('Invalid port or port range');
            return true;
        };

        o = s.taboption('general', form.ListValue, 'class', _('DSCP Class'));
        o.value('ef', _('EF - Expedited Forwarding (46)'));
        o.value('cs5', _('CS5 (40)'));
        o.value('cs6', _('CS6 (48)'));
        o.value('cs7', _('CS7 (56)'));
        o.value('cs4', _('CS4 (32)'));
        o.value('af41', _('AF41 (34)'));
        o.value('af42', _('AF42 (36)'));
        o.value('cs2', _('CS2 (16)'));
        o.value('cs1', _('CS1 (8)'));
        o.value('cs0', _('CS0 - Best Effort (0)'));
        o.rmempty = false;

        o = s.taboption('general', form.Flag, 'counter', _('Enable counter'));
        o.rmempty = false;

        o = s.taboption('general', form.Flag, 'enabled', _('Enable'));
        o.rmempty = false;
        o.editable = true;
        o.default = '1';  // Set default value to enabled
        o.write = function(section_id, formvalue) {
            // Always write the value, whether it's '0' or '1'
            uci.set('qosmate', section_id, 'enabled', formvalue);
        };
        o.load = function(section_id) {
            var value = uci.get('qosmate', section_id, 'enabled');
            // If the value is undefined (not set in config), return '1' (enabled)
            return (value === undefined) ? '1' : value;
        };        

        return m.render();
    }
});
