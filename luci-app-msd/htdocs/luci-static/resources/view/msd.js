'use strict';
'require form';
'require view';
'require uci';
'require fs';
'require tools.widgets as widgets';

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('msd'),
        ]);
    },
    render: function (data) {
        let m, s, o;

        m = new form.Map('msd', _('MSD'), _('MSD is a program for organizing IPTV streaming on the network via HTTP.'));

        s = m.section(form.NamedSection, 'config', 'config');

        s.tab('basic', _('Basic Config'));

        o = s.taboption('basic', form.Flag, 'enabled', _('Enable'));
        o.rmempty = false;

        o = s.taboption('basic', form.Value, 'bind_address', _('Bind Address'));
        o.datatype = 'hostport';
        o.placeholder = '0.0.0.0:7088';

        o = s.taboption('basic', widgets.DeviceSelect, 'bind_interface', _('Bind Interface'));
        o.optional = true;
        o.rmempty = false;
        o.noaliases = true;

        o = s.taboption('basic', widgets.DeviceSelect, 'source_interface', _('Source Interface'));
        o.optional = false;
        o.rmempty = false;
        o.noaliases = true;

        s.tab('advanced', _('Advanced Config'));

        o = s.taboption('advanced', form.Value, 'thread_count', _('Thread Count'));
        o.datatype = 'uinteger';
        o.placeholder = '0';

        o = s.taboption('advanced', form.Flag, 'thread_bind_cpu', _('Thread Bind CPU'));
        o.rmempty = false;

        o = s.taboption('advanced', form.Flag, 'hub_drop_slow_client', _('Drop Slow Client'));
        o.rmempty = false;

        o = s.taboption('advanced', form.Flag, 'hub_use_polling_for_send', _('Use Polling For Send'));
        o.rmempty = false;

        o = s.taboption('advanced', form.Flag, 'hub_zero_copy_on_send', _('Zero Copy On Send'));
        o.rmempty = false;

        o = s.taboption('advanced', form.Flag, 'hub_persist_when_no_source', _('Persist Hub When No Avalible Source'));
        o.rmempty = false;

        o = s.taboption('advanced', form.Flag, 'hub_persist_when_no_client', _('Persist Hub When No Conectted Client'));
        o.rmempty = false;

        o = s.taboption('advanced', form.Value, 'hub_destroy_when_no_client_timeout', _('Destroy Hub Timeout(No Connectted Client)'));
        o.datatype = 'uinteger';
        o.placeholder = '60';
        o.retain = true;
        o.depends('hub_persist_when_no_client', '0');

        o = s.taboption('advanced', form.Flag, 'hub_wait_precache', _('Wait Precache'));
        o.rmempty = false;

        o = s.taboption('advanced', form.Value, 'hub_precache_size', _('Precache Size'));
        o.datatype = 'uinteger';
        o.placeholder = '2048';

        o = s.taboption('advanced', form.Value, 'source_ring_buffer_size', _('Ring Buffer Size'));
        o.datatype = 'uinteger';
        o.placeholder = '8192';

        o = s.taboption('advanced', form.Value, 'source_multicast_rejoin_interval', _('Multicast Rejoin Interval'));
        o.datatype = 'uinteger';
        o.placeholder = '180';

        return m.render();
    }
});
