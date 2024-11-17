'use strict';
'require view';
'require form';
'require fs';

return view.extend({

    load: function() {
        return Promise.all([
            L.resolveDefault(fs.stat('/var/etc/xjay/config.json'), null)
        ]).then(function(stat) {
            var conf = stat[0] ? stat[0].path : null;

            if (conf == null)
                return 'The config file does not exist!';

            return fs.exec_direct('/bin/cat', [ conf ]).catch(function(err) {
                ui.addNotification(null, E('p', {}, _('Unable to load config file: ' + err.message)));
                return '';
            });
        });
    },

    render:function(conf_data){
        var m, s, o;
        m = new form.Map('xjay', _('Misc.'), _('Misc. settings for xjay.'));

        s = m.section(form.TypedSection, 'misc', _('Misc Configurations'));
        s.addremove = false;
        s.anonymous = true;

        // as blow are some log options
        s.tab('log', _('Log'));

        o = s.taboption('log', form.ListValue, 'log_level', _('Log Level'), _('Read Xray log in "System Log" or use <code>logread</code> command.'));
        o.value("debug");
        o.value("info");
        o.value("warning");
        o.value("error");
        o.value("none");

        o = s.taboption('log', form.Flag, 'log_access', _('Enable Access Log'), _('Access log will also be written to System Log.'));
        o.enabled = 'true';
        o.disabled = 'false';

        o = s.taboption('log', form.Flag, 'log_error', _('Enable Error Log'), _('Error log will also be written to System Log.'));
        o.enabled = 'true';
        o.disabled = 'false';

        o = s.taboption('log', form.Flag, 'log_dnslog', _('Enable DNS Log'), _('DNS log will also be written to System Log.'));
        o.enabled = 'true';
        o.disabled = 'false';

        // as blow are some log options
        s.tab('path', _('Path'));

        o = s.taboption('path', form.Value, 'xray_path', _('Xray Executable Path'), 'Please check if it is right file location for xray bin, or this will not work!');
        o.datatype = 'directory';

        // as blow is the xray config view
        s.tab('config', _('Config'));

        o = s.taboption("config", form.DummyValue, "_configview");
        o.render = L.bind(function() {
            var conf_lines = conf_data.trim().split(/\n/);

            return E([], [
                E('h2', {}, [ _('Xray Config File') ]),
                E('div', { 'id': 'content_config' }, [
                    E('textarea', {
                        'id': 'xray_config',
                        'style': 'font-size:14px',
                        'style': 'width:100%',
                        'readonly': 'readonly',
                        'wrap': 'off',
                        'rows': conf_lines.length + 1
                    }, [ conf_lines.join('\n') ])
                ])
            ]);
        }, o, this);

        return m.render();
    }

});
