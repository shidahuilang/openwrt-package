'use strict';
'require view';
'require form';
'require ui';
'require uci';
'require rpc';
'require fs';

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

        m = new form.Map('qosmate', _('QoSmate CAKE Settings'), _('Configure CAKE settings for QoSmate.'));

        s = m.section(form.NamedSection, 'cake', 'cake', _('CAKE Settings'));
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
                    return true;
                };
            }
            return opt;
        }

        o = s.option(form.ListValue, 'COMMON_LINK_PRESETS', _('Common Link Presets'), _('Select common link presets'));
        o.value('raw', _('Raw (No overhead compensation)'));
        o.value('conservative', _('Conservative (48 bytes overhead + ATM)'));
        o.value('ethernet', _('Ethernet'));
        o.value('docsis', _('DOCSIS cable'));
        o.value('pppoa-vcmux', _('PPPoA VC-Mux'));
        o.value('pppoa-llc', _('PPPoA LLC'));
        o.value('pppoe-vcmux', _('PPPoE VC-Mux'));
        o.value('pppoe-llcsnap', _('PPPoE LLC-SNAP'));
        o.value('bridged-vcmux', _('Bridged VC-Mux'));
        o.value('bridged-llcsnap', _('Bridged LLC-SNAP'));
        o.value('ipoa-vcmux', _('IPoA VC-Mux'));
        o.value('ipoa-llcsnap', _('IPoA LLC-SNAP'));
        o.value('pppoe-ptm', _('PPPoE PTM'));
        o.value('bridged-ptm', _('Bridged PTM'));
        o.default = 'ethernet';

        createOption('OVERHEAD', _('Overhead'), _('Set the overhead'), _('Default: based on preset'));
        createOption('MPU', _('MPU'), _('Minimum packet size CAKE will account for'), _('Default: based on preset'), 'uinteger');
        createOption('LINK_COMPENSATION', _('Link Compensation'), _('Set the link compensation'), _('Default: based on preset'));
        createOption('ETHER_VLAN_KEYWORD', _('Ether VLAN Keyword'), _('Set the Ether VLAN keyword'), _('Default: none'));

        o = s.option(form.ListValue, 'PRIORITY_QUEUE_INGRESS', _('Priority Queue (Ingress)'), _('Sets CAKE\'s diffserv mode for incoming traffic'));
        o.value('diffserv3', _('Diffserv 3-tier priority'));
        o.value('diffserv4', _('Diffserv 4-tier priority'));
        o.value('diffserv8', _('Diffserv 8-tier priority'));
        o.default = 'diffserv4';

        o = s.option(form.ListValue, 'PRIORITY_QUEUE_EGRESS', _('Priority Queue (Egress)'), _('Sets CAKE\'s diffserv mode for outgoing traffic'));
        o.value('diffserv3', _('Diffserv 3-tier priority'));
        o.value('diffserv4', _('Diffserv 4-tier priority'));
        o.value('diffserv8', _('Diffserv 8-tier priority'));
        o.default = 'diffserv4';

        o = s.option(form.Flag, 'HOST_ISOLATION', _('Host Isolation'), _('Applies fairness first by host, then by flow(dual-srchost/dual-dsthost)'));
        o.rmempty = false;
        o.default = '1';

        o = s.option(form.Flag, 'NAT_INGRESS', _('NAT (Ingress)'), _('Enable NAT lookup for ingress'));
        o.rmempty = false;
        o.default = '1';

        o = s.option(form.Flag, 'NAT_EGRESS', _('NAT (Egress)'), _('Enable NAT lookup for egress'));
        o.rmempty = false;
        o.default = '1';

        o = s.option(form.ListValue, 'ACK_FILTER_EGRESS', _('ACK Filter (Egress)'), 
            _('Set ACK filter for egress. Auto enables filtering if download/upload ratio ≥ 15.'));
        o.value('auto', _('Auto'));
        o.value('1', _('Enable'));
        o.value('0', _('Disable'));
        o.default = 'auto';

        createOption('RTT', _('RTT'), _('Set the Round Trip Time'), _('Default: auto'), 'uinteger');

        o = s.option(form.Flag, 'AUTORATE_INGRESS', _('Autorate (Ingress)'), _('Enable autorate for ingress'));
        o.rmempty = false;
        o.default = '0';

        createOption('EXTRA_PARAMETERS_INGRESS', _('Extra Parameters (Ingress)'), _('Set extra parameters for ingress'), _('Default: none'));
        createOption('EXTRA_PARAMETERS_EGRESS', _('Extra Parameters (Egress)'), _('Set extra parameters for egress'), _('Default: none'));

        return m.render();
    }
});
