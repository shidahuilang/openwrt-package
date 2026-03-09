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
        var m = new form.Map('taskplan', _('Scheduled Tasks'), 
            _('<b>The original [Timing Settings] includes scheduled task execution and startup task execution. Presets include over 10 functions, including restart, shutdown, network restart, memory release, system cleaning, network sharing, network shutdown, automatic detection of network disconnects and reconnection, MWAN3 load balancing detection of reconnection, and custom scripts</b></br>') +
            _('N1-N5 is continuous, N1, N3, N5 is discontinuous, */N represents every N hours or every N minutes.The week can only be 0~6, the hour can only be 0~23, the minute can only be 0~59, the unavailable time is 48 hours.'));

        var s = m.section(form.TypedSection, 'global');
        s.anonymous = true;

        var e = s.option(form.TextValue, 'customscript', _('Edit Custom Script'));
        e.description = _('Shell commands for [Customscript] task type');
        e.rows = 5;
        e.default = '#!/bin/bash\n# Add your commands here';
        e.optional = false;

        e = s.option(form.TextValue, 'customscript2', _('Edit Custom Script2'));
        e.description = _('Shell commands for [Customscript2] task type');
        e.rows = 5;
        e.default = '#!/bin/bash\n# Add your commands here';
        e.optional = false;

        var ss = m.section(form.TypedSection, 'stime', '');
        ss.addremove = true;
        ss.anonymous = true;
        ss.sortable = true;
        ss.template = 'cbi/tblsection';

        var remarks = ss.option(form.Value, 'remarks', _('Remarks'));
        remarks.optional = false;

        var enable = ss.option(form.Flag, 'enable', _('Enable'));
        enable.rmempty = false;
        enable.default = 1;

        var stype = ss.option(form.ListValue, 'stype', _('Scheduled Type'));
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
        stype.default = 1;

        var month = ss.option(form.Value, 'month', _('Month(0~11)'));
        month.rmempty = false;
        month.default = '*';
        month.datatype = 'string';

        var week = ss.option(form.Value, 'week', _('Week Day(0~6)'));
        week.rmempty = true;
        week.value('*', _('Everyday'));
        week.value('0', _('Sunday'));
        week.value('1', _('Monday'));
        week.value('2', _('Tuesday'));
        week.value('3', _('Wednesday'));
        week.value('4', _('Thursday'));
        week.value('5', _('Friday'));
        week.value('6', _('Saturday'));
        week.default = '*';
        week.datatype = 'string';

        var hour = ss.option(form.Value, 'hour', _('Hour(0~23)'));
        hour.description = _('1-8 is the continuous time from 1-8 clock; 11,12,16 clock are discontinuous; */3 represents every 3 hours; * every hour.');
        hour.rmempty = false;
        hour.default = 0;
        hour.datatype = 'string';

        var minute = ss.option(form.Value, 'minute', _('Minute(0~59)'));
        minute.description = _('1-30 is continuous 1-30 minutes; 7,8,9 minutes discontinuous ; */5 means every 5 minutes ; * every minutes.');
        minute.rmempty = false;
        minute.default = 0;
        minute.datatype = 'string';

        m.apply_on_parse = true;
        m.on_after_apply = function() {
            return callExec('/etc/init.d/taskplan start').then(function() {
                ui.addNotification(null, E('p', {}, _('Tasks updated')));
            });
        };

        return m.render();
    }
});
