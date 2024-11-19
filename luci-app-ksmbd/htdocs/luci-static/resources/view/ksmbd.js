'use strict';
'require view';
'require fs';
'require form';
'require uci';
'require tools.widgets as widgets';

return view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(fs.stat('/sbin/block'), null),
			L.resolveDefault(fs.stat('/etc/config/fstab'), null),
			L.resolveDefault(fs.exec('/usr/sbin/ksmbd.mountd', ['-V']), {}).then(function(res) { return L.toArray((res.stdout || '').match(/version : (\S+)/))[1] }),
			L.resolveDefault(fs.exec('/sbin/modinfo', ['ksmbd']), {}).then(function(res) { return L.toArray((res.stdout || '').match(/vermagic:\t(\S+)/))[1] }),
		]);
	},
	render: function(stats) {
		var m, s, o, v, v2;
		v = '?';
		v2 = '?';

		m = new form.Map('ksmbd', _('Network Shares'));

		if (stats[2])
			v = stats[2].trim();
		if (stats[3])
			v2 = stats[3].trim();
		if (v != v2)
			v = v +'/'+ v2;
		s = m.section(form.TypedSection, 'globals', 'Ksmbd/Kmod Version ' + v);
		s.anonymous = true;

		s.tab('general',  _('General Settings'));
		s.tab('template', _('Edit Template'), _('Edit the template that is used for generating the ksmbd configuration.'));

		o = s.taboption('general', widgets.NetworkSelect, 'interface', _('Interface'),
			_('Listen only on the given interface or, if unspecified, on lan'));
		o.multiple = true;
		o.cfgvalue = (section_id => L.toArray(uci.get('ksmbd', section_id, 'interface')));
		o.write = function(section_id, formvalue) {
			var cfgvalue = this.cfgvalue(section_id),
			    oldNetworks = L.toArray(cfgvalue),
			    newNetworks = L.toArray(formvalue);
			oldNetworks.sort();
			newNetworks.sort();
			if (oldNetworks.join(' ') == newNetworks.join(' '))
				return;
			return uci.set('ksmbd', section_id, 'interface', newNetworks.join(' '));
		};

		o = s.taboption('general', form.Value, 'workgroup', _('Workgroup'));
		o.placeholder = 'WORKGROUP';

		o = s.taboption('general', form.Value, 'description', _('Description'));
		o.placeholder = 'Ksmbd on OpenWrt';
		
		o = s.taboption('general', form.Flag, 'allow_legacy_protocols', _('Allow legacy (insecure) protocols/authentication.'),
			_('Allow legacy smb(v1)/Lanman connections, needed for older devices without smb(v2.1/3) support.'));

		o = s.taboption('template', form.TextValue, '_tmpl',
			null,
			_("This is the content of the file '/etc/ksmbd/ksmbd.conf.template' from which your ksmbd configuration will be generated. \
			Values enclosed by pipe symbols ('|') should not be changed. They get their values from the 'General Settings' tab."));
		o.rows = 20;
		o.cfgvalue = function(section_id) {
			return fs.trimmed('/etc/ksmbd/ksmbd.conf.template');
		};
		o.write = function(section_id, formvalue) {
			return fs.write('/etc/ksmbd/ksmbd.conf.template', formvalue.trim().replace(/\r\n/g, '\n') + '\n');
		};


		s = m.section(form.TableSection, 'share', _('Shared Directories'),
			_('Please add directories to share. Each directory refers to a folder on a mounted device.'));
		s.anonymous = true;
		s.addremove = true;

		s.option(form.Value, 'name', _('Name'));
		o = s.option(form.Value, 'path', _('Path'));
		if (stats[0] && stats[1]) {
			o.titleref = L.url('admin', 'system', 'mounts');
		}

		o = s.option(form.Flag, 'browseable', _('Browse-able'));
		o.enabled = 'yes';
		o.disabled = 'no';
		o.default = 'yes';

		o = s.option(form.Flag, 'read_only', _('Read-only'));
		o.enabled = 'yes';
		o.disabled = 'no';
		o.default = 'no'; // ksmbd.conf default is 'yes'
		o.rmempty = false;

		s.option(form.Flag, 'force_root', _('Force Root'));

		o = s.option(form.Value, 'users', _('Allowed users'));
		o.rmempty = true;

		o = s.option(form.Flag, 'guest_ok', _('Allow guests'));
		o.enabled = 'yes';
		o.disabled = 'no';
		o.default = 'yes'; // ksmbd.conf default is 'no'
		o.rmempty = false;

		o = s.option(form.Flag, 'inherit_owner', _('Inherit owner'));
		o.enabled = 'yes';
		o.disabled = 'no';
		o.default = 'no';

		o = s.option(form.Flag, 'hide_dot_files', _('Hide dot files'));
		o.enabled = 'yes';
		o.disabled = 'no';
		o.default = 'yes';

		o = s.option(form.Value, 'create_mask', _('Create mask'));
		o.maxlength = 4;
		o.default = '0666'; // ksmbd.conf default is '0744'
		o.placeholder = '0666';
		o.rmempty = false;

		o = s.option(form.Value, 'dir_mask', _('Directory mask'));
		o.maxlength = 4;
		o.default = '0777'; // ksmbd.conf default is '0755'
		o.placeholder = '0777';
		o.rmempty = false;

		return m.render();
	}
});
