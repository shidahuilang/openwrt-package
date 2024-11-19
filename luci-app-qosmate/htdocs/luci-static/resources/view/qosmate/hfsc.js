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

        m = new form.Map('qosmate', _('QoSmate HFSC Settings'), _('Configure HFSC settings for QoSmate.'));

        s = m.section(form.NamedSection, 'hfsc', 'hfsc', _('HFSC Settings'));
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

        o = s.option(form.ListValue, 'LINKTYPE', _('Link Type'), _('Select the link type'));
        o.value('ethernet', _('Ethernet'));
        o.value('atm', _('ATM'));
        o.value('adsl', _('ADSL'));
        o.default = 'ethernet';

        createOption('OH', _('Overhead'), _('Set the overhead'), _('Default: 44'), 'uinteger');

        o = s.option(form.ListValue, 'gameqdisc', _('Game Queue Discipline'), _('Queueing method for traffic classified as realtime'));
        o.value('pfifo', _('PFIFO'));
        o.value('fq_codel', _('FQ_CODEL'));
        o.value('bfifo', _('BFIFO'));
        o.value('red', _('RED'));
        o.value('netem', _('NETEM'));
        o.default = 'pfifo';

        createOption('GAMEUP', _('Game Upload (kbps)'), _('Bandwidth reserved for realtime upload traffic'), _('Default: 15% of UPRATE + 400'), 'uinteger');
        createOption('GAMEDOWN', _('Game Download (kbps)'), _('Bandwidth reserved for realtime download traffic'), _('Default: 15% of DOWNRATE + 400'), 'uinteger');

        o = s.option(form.ListValue, 'nongameqdisc', _('Non-Game Queue Discipline'), _('Select the queueing discipline for non-realtime traffic'));
        o.value('fq_codel', _('FQ_CODEL'));
        o.value('cake', _('CAKE'));
        o.default = 'fq_codel';

        createOption('nongameqdiscoptions', _('Non-Game QDisc Options'), _('Cake options for non-realtime queueing discipline'), _('Default: besteffort ack-filter'));
        createOption('MAXDEL', _('Max Delay (ms)'), _('Target max delay for realtime packets after burst (pfifo, bfifo, red)'), _('Default: 24'), 'uinteger');
        createOption('PFIFOMIN', _('PFIFO Min'), _('Minimum packet count for PFIFO queue'), _('Default: 5'), 'uinteger');
        createOption('PACKETSIZE', _('Avg Packet Size (B)'), _('Used with PFIFOMIN to calculate PFIFO limit'), _('Default: 450'), 'uinteger');
        createOption('netemdelayms', _('NETEM Delay (ms)'), _('NETEM delay in milliseconds'), _('Default: 30'), 'uinteger');
        createOption('netemjitterms', _('NETEM Jitter (ms)'), _('NETEM jitter in milliseconds'), _('Default: 7'), 'uinteger');
        
        o = s.option(form.ListValue, 'netemdist', _('NETEM Distribution'), _('NETEM delay distribution'));
        o.value('experimental', _('Experimental'));
        o.value('normal', _('Normal'));
        o.value('pareto', _('Pareto'));
        o.value('paretonormal', _('Pareto Normal'));
        o.default = 'normal';

        createOption('pktlossp', _('Packet Loss Percentage'), _('Percentage of packet loss'), _('Default: none'));

        return m.render();
    }
});
