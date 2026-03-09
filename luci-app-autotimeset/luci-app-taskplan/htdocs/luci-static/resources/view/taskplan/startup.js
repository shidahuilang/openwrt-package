'use strict';
'require view';
'require form';
'require ui';
'require uci';
'require rpc';

var callExec = rpc.declare({
    object: 'luci',
    method: 'exec',
    params: ['command'],
    expect: { result: 0 }
});

return view.extend({
    load: function() {
        return uci.load('taskplan');
    },

    render: function(data) {
        var m = new form.Map('taskplan', _('Startup Tasks'), 
            _('<b>The original [Timing Settings] includes scheduled task execution and startup task execution. Presets include over 10 functions, including restart, shutdown, network restart, memory release, system cleaning, network sharing, network shutdown, automatic detection of network disconnects and reconnection, MWAN3 load balancing detection of reconnection, and custom scripts</b></br>') +
            _('The task to be executed upon startup, with a startup delay time unit of seconds.'));

        var s = m.section(form.TypedSection, 'global');
        s.anonymous = true;

        var e = s.option(form.TextValue, 'customscript', _('Edit Custom Script'));
        e.description = _('Shell commands for Customscript task type');
        e.rows = 5;
        e.default = '#!/bin/sh\n# Add your commands here';
        e.optional = false;

        e = s.option(form.TextValue, 'customscript2', _('Edit Custom Script2'));
        e.description = _('Shell commands for Customscript2 task type');
        e.rows = 5;
        e.default = '#!/bin/sh\n# Add your commands here';
        e.optional = false;

        var ls = m.section(form.TypedSection, 'ltime', '');
        ls.addremove = true;
        ls.anonymous = true;
        ls.sortable = true;
        ls.template = 'cbi/tblsection';

        var remarks = ls.option(form.Value, 'remarks', _('Remarks'));
        remarks.optional = false;

        var enable = ls.option(form.Flag, 'enable', _('Enable'));
        enable.rmempty = false;
        enable.default = 1;

        var stype = ls.option(form.ListValue, 'stype', _('Startup Type'));
        stype.description = _('Action to perform at system startup');
        stype.value(1, _('Scheduled Reboot'));
        stype.value(2, _('Scheduled Poweroff'));
        stype.value(3, _('Scheduled ReNetwork'));
        stype.value(4, _('Scheduled RestartSamba'));
        stype.value(5, _('Scheduled Restartwan'));
        stype.value(6, _('Scheduled Closewan'));
        stype.value(7, _('Scheduled Clearmem'));
        stype.value(8, _('Scheduled Sysfree'));
        stype.value(9, _('Scheduled DisReconn'));
        stype.value(10, _('Scheduled DisRereboot'));
        stype.value(11, _('Scheduled Restartmwan3'));
        stype.value(13, _('Scheduled Wifiup'));
        stype.value(14, _('Scheduled Wifidown'));
        stype.value(12, _('Scheduled Customscript'));
        stype.value(15, _('Scheduled Customscript2'));
        stype.default = 12;

        var delay = ls.option(form.Value, 'delay', _('Delayed Start(seconds)'));
        delay.description = _('Seconds to wait after boot before execution');
        delay.datatype = 'uinteger';
        delay.default = 10;
        delay.optional = false;

        m.apply_on_parse = true;
        m.on_after_apply = function() {
            return callExec('/etc/init.d/taskplan start').then(function() {
                ui.addNotification(null, E('p', {}, _('Tasks updated')));
            });
        };

        return m.render();
    }
});
