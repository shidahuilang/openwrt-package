'use strict';
'require view';
'require uci';
'require fs';
'require form';
'require tools.widgets as widgets';
'require shadowsocks-rust as ss';

var conf = 'shadowsocks-rust';

function src_dst_option(s /*, ... */) {
	var o = s.taboption.apply(s, L.varargs(arguments, 1));
	o.datatype = 'or(ipaddr,cidr)';
}

return view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(fs.stat('/usr/share/ssrules'), null),
			uci.load(conf).then(function() {
				if (!uci.get_first(conf, 'ss_rules')) {
					uci.set(conf, uci.add(conf, 'ss_rules', 'ss_rules'), 'disabled', '1');
				}
			})
		]);
	},
	render: function(stats) {
		var m, s, o;

		m = new form.Map(conf, _('Redir Rules'),
			_('On this page you can configure how traffics are to be \
				forwarded to ss-redir instances. \
				If enabled, packets will first have their src ip addresses checked \
				against <em>Src ip/net bypass</em>, <em>Src ip/net forward</em>, \
				<em>Src ip/net checkdst</em> and if none matches <em>Src default</em> \
				will give the default action to be taken. \
				If the prior check results in action <em>checkdst</em>, packets will continue \
				to have their dst addresses checked.'));

		s = m.section(form.NamedSection, 'ss_rules', 'ss_rules');
		s.tab('general', _('General Settings'));
		s.tab('src', _('Source Settings'));
		s.tab('dst', _('Destination Settings'));

		s.taboption('general', form.Flag, 'disabled', _('Disable'));
		if (!stats[0]) {
			ss.option_install_package(s, 'general');
		}

		o = s.taboption('general', form.ListValue, 'redir_tcp',
			_('ss-redir for TCP'));
		ss.values_redir(o, 'tcp');
		o = s.taboption('general', form.ListValue, 'redir_udp',
			_('ss-redir for UDP'));
		ss.values_redir(o, 'udp');

		o = s.taboption('general', form.ListValue, 'local_default',
			_('Local-out default'),
			_('Default action for locally generated TCP packets'));
		ss.values_actions(o);
		o = s.taboption('general', widgets.DeviceSelect, 'ifnames',
			_('Ingress interfaces'),
			_('Only apply rules on packets from these network interfaces'));
		o.multiple = true;
		o.noaliases = true;
		o.noinactive = true;
		s.taboption('general', form.Value, 'nft_tcp_extra',
			_('Extra tcp expression'),
			_('Extra nftables expression for matching tcp traffics, e.g. "tcp dport { 80, 443 }"'));
		s.taboption('general', form.Value, 'nft_udp_extra',
			_('Extra udp expression'),
			_('Extra nftables expression for matching udp traffics, e.g. "udp dport { 53 }"'));

		src_dst_option(s, 'src', form.DynamicList, 'src_ips_bypass',
			_('Src ip/net bypass'),
			_('Bypass ss-redir for packets with src address in this list'));
		src_dst_option(s, 'src', form.DynamicList, 'src_ips_forward',
			_('Src ip/net forward'),
			_('Forward through ss-redir for packets with src address in this list'));
		src_dst_option(s, 'src', form.DynamicList, 'src_ips_checkdst',
			_('Src ip/net checkdst'),
			_('Continue to have dst address checked for packets with src address in this list'));
		o = s.taboption('src', form.ListValue, 'src_default',
			_('Src default'),
			_('Default action for packets whose src address do not match any of the src ip/net list'));
		ss.values_actions(o);

		src_dst_option(s, 'dst', form.DynamicList, 'dst_ips_bypass',
			_('Dst ip/net bypass'),
			_('Bypass ss-redir for packets with dst address in this list'));
		src_dst_option(s, 'dst', form.DynamicList, 'dst_ips_forward',
			_('Dst ip/net forward'),
			_('Forward through ss-redir for packets with dst address in this list'));

		var dir = '/etc/shadowsocks-rust';
		o = s.taboption('dst', form.FileUpload, 'dst_ips_bypass_file',
			_('Dst ip/net bypass file'),
			_('File containing ip/net for the purposes as with <em>Dst ip/net bypass</em>'));
		o.root_directory = dir;
		o = s.taboption('dst', form.FileUpload, 'dst_ips_forward_file',
			_('Dst ip/net forward file'),
			_('File containing ip/net for the purposes as with <em>Dst ip/net forward</em>'));
		o.root_directory = dir;
		o = s.taboption('dst', form.ListValue, 'dst_default',
			_('Dst default'),
			_('Default action for packets whose dst address do not match any of the dst ip list'));
		ss.values_actions(o);

		return m.render();
	},
});
