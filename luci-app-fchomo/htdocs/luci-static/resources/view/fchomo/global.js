'use strict';
'require form';
'require network';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';

'require fchomo as hm';
'require tools.firewall as fwtool';
'require tools.widgets as widgets';

var callResVersion = rpc.declare({
	object: 'luci.fchomo',
	method: 'resources_get_version',
	params: ['type', 'repo'],
	expect: { '': {} }
});

var callCrondSet = rpc.declare({
	object: 'luci.fchomo',
	method: 'crond_set',
	params: ['type', 'expr'],
	expect: { '': {} }
});

function handleResUpdate(type, repo) {
	var callResUpdate = rpc.declare({
		object: 'luci.fchomo',
		method: 'resources_update',
		params: ['type', 'repo'],
		expect: { '': {} }
	});

	// Dynamic repo
	var label;
	if (repo) {
		var section_id = this.section.section;
		var weight = document.getElementById(this.cbid(section_id));
		if (weight)
			repo = weight.firstChild.value,
			label = weight.firstChild.selectedOptions[0].label;
	}

	return L.resolveDefault(callResUpdate(type, repo), {}).then((res) => {
		switch (res.status) {
		case 0:
			this.description = (repo ? label + ' ' : '') + _('Successfully updated.');
			break;
		case 1:
			this.description = (repo ? label + ' ' : '') + _('Update failed.');
			break;
		case 2:
			this.description = (repo ? label + ' ' : '') + _('Already in updating.');
			break;
		case 3:
			this.description = (repo ? label + ' ' : '') + _('Already at the latest version.');
			break;
		default:
			this.description = (repo ? label + ' ' : '') + _('Unknown error.');
			break;
		}

		return this.map.reset();
	});
}

function renderResVersion(El, type, repo) {
	return L.resolveDefault(callResVersion(type, repo), {}).then((res) => {
		var resEl = E([
			E('button', {
				'class': 'cbi-button cbi-button-apply',
				'click': ui.createHandlerFn(this, handleResUpdate, type, repo)
			}, [ _('Check update') ]),
			updateResVersion(E('span', { style: 'border: unset; font-weight: bold; align-items: center' }), res.version)
		]);

		if (El) {
			El.appendChild(resEl);
			El.lastChild.style.display = 'flex';
		} else
			El = resEl;

		return El;
	});
}

function updateResVersion(El, version) {
	if (El) {
		El.style.color = version ? 'green' : 'red';
		El.innerHTML = '&ensp;%s'.format(version || _('not found'));
	}

	return El;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('fchomo'),
			hm.getFeatures(),
			network.getHostHints(),
			hm.getServiceStatus('mihomo-c'),
			hm.getClashAPI('mihomo-c'),
			hm.getServiceStatus('mihomo-s'),
			hm.getClashAPI('mihomo-s'),
			callResVersion('geoip').then((res) => { return res.version }),
			callResVersion('geosite').then((res) => { return res.version })
		]);
	},

	render: function(data) {
		var features = data[1],
		    hosts = data[2]?.hosts,
		    CisRunning = data[3],
		    CclashAPI = data[4],
		    SisRunning = data[5],
		    SclashAPI = data[6],
		    res_ver_geoip = data[7],
		    res_ver_geosite = data[8];

		var dashboard_repo = uci.get(data[0], 'api', 'dashboard_repo');

		var m, s, o, ss, so;

		m = new form.Map('fchomo', _('FullCombo Mihomo'),
			'<img src="' + hm.sharktaikogif + '" title="Ciallo～(∠・ω< )⌒☆" height="52"></img>');

		s = m.section(form.NamedSection, 'config', 'fchomo');

		/* Overview START */
		s.tab('status', _('Overview'));

		/* Service status */
		o = s.taboption('status', form.SectionValue, '_status', form.NamedSection, 'config', 'fchomo', _('Service status'));
		ss = o.subsection;

		so = ss.option(form.DummyValue, '_core_version', _('Core version'));
		so.cfgvalue = function() {
			return E('strong', [features.core_version || _('Unknown')]);
		}

		so = ss.option(form.DummyValue, '_luciapp_version', _('Application version'));
		so.cfgvalue = function() {
			return E('strong', [features.luciapp_version || _('Unknown')]);
		}

		so = ss.option(form.DummyValue, '_client_status', _('Client status'));
		so.cfgvalue = function() { return hm.renderStatus(hm, '_client_bar', CisRunning ? { ...CclashAPI, dashboard_repo: dashboard_repo } : false, 'mihomo-c') }
		poll.add(function() {
			return hm.getServiceStatus('mihomo-c').then((isRunning) => {
				hm.updateStatus(hm, document.getElementById('_client_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-c');
			});
		})

		so = ss.option(form.DummyValue, '_server_status', _('Server status'));
		so.cfgvalue = function() { return hm.renderStatus(hm, '_server_bar', SisRunning ? { ...SclashAPI, dashboard_repo: dashboard_repo } : false, 'mihomo-s') }
		poll.add(function() {
			return hm.getServiceStatus('mihomo-s').then((isRunning) => {
				hm.updateStatus(hm, document.getElementById('_server_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-s');
			});
		})

		so = ss.option(form.Button, '_reload', _('Reload All'));
		so.inputtitle = _('Reload');
		so.inputstyle = 'apply';
		so.onclick = L.bind(hm.handleReload, so, null);

		so = ss.option(form.DummyValue, '_conn_check', _('Connection check'));
		so.cfgvalue = function() {
			var callConnStat = rpc.declare({
				object: 'luci.fchomo',
				method: 'connection_check',
				params: ['url'],
				expect: { '': {} }
			});

			var ElId = '_connection_check_results';

			return E([
				E('button', {
					'class': 'cbi-button cbi-button-apply',
					'click': ui.createHandlerFn(this, function() {
						var weight = document.getElementById(ElId);

						weight.innerHTML = '';
						return hm.checkurls.forEach((site) => {
							L.resolveDefault(callConnStat(site[0]), {}).then((res) => {
								weight.innerHTML += '<span style="color:%s">&ensp;%s</span>'.format((res.httpcode && res.httpcode.match(/^20\d$/)) ? 'green' : 'red', site[1]);
							});
						});
					})
				}, [ _('Check') ]),
				E('strong', { id: ElId }, [
					E('span', { style: 'color:gray' }, ' ' + _('unchecked'))
				])
			]);
		}

		/* Resources management */
		o = s.taboption('status', form.SectionValue, '_config', form.NamedSection, 'resources', 'fchomo', _('Resources management'));
		ss = o.subsection;

		if (!res_ver_geoip || !res_ver_geosite) {
			so = ss.option(form.Button, '_upload_initia', _('Upload initial package'));
			so.inputstyle = 'action';
			so.inputtitle = _('Upload...');
			so.onclick = L.bind(hm.uploadInitialPack, so);
		}

		so = ss.option(form.Flag, 'auto_update', _('Auto update'),
			_('Auto update resources.'));
		so.default = so.disabled;
		so.rmempty = false;
		so.write = function(section_id, formvalue) {
			if (formvalue == 1) {
				callCrondSet('resources', uci.get(data[0], section_id, 'auto_update_expr'));
			} else
				callCrondSet('resources');

			return this.super('write', section_id, formvalue);
		}

		so = ss.option(form.Value, 'auto_update_expr', _('Cron expression'),
			_('The default value is 2:00 every day.'));
		so.default = '0 2 * * *';
		so.placeholder = '0 2 * * *';
		so.rmempty = false;
		so.retain = true;
		so.depends('auto_update', '1');
		so.write = function(section_id, formvalue) {
			callCrondSet('resources', formvalue);

			return this.super('write', section_id, formvalue);
		};
		so.remove = function(section_id) {
			callCrondSet('resources');

			return this.super('remove', section_id);
		};

		so = ss.option(form.ListValue, '_dashboard_version', _('Dashboard version'));
		so.default = hm.dashrepos[0][0];
		hm.dashrepos.forEach((repo) => {
			so.value.apply(so, repo);
		})
		so.renderWidget = function(/* ... */) {
			var El = form.ListValue.prototype.renderWidget.apply(this, arguments);

			El.className = 'control-group';
			El.firstChild.style.width = '10em';

			return renderResVersion.call(this, El, 'dashboard', this.default);
		}
		so.onchange = function(ev, section_id, value) {
			this.default = value;

			var weight = ev.target;
			if (weight)
				return L.resolveDefault(callResVersion('dashboard', value), {}).then((res) => {
					updateResVersion(weight.lastChild, res.version);
				});
		}
		so.write = function() {};

		so = ss.option(form.DummyValue, '_geoip_version', _('GeoIP version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'geoip') };

		so = ss.option(form.DummyValue, '_geosite_version', _('GeoSite version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'geosite') };

		so = ss.option(form.DummyValue, '_asn_version', _('ASN version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'asn') };

		so = ss.option(form.DummyValue, '_china_ip4_version', _('China IPv4 list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'china_ip4') };

		so = ss.option(form.DummyValue, '_china_ip6_version', _('China IPv6 list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'china_ip6') };

		so = ss.option(form.DummyValue, '_gfw_list_version', _('GFW list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'gfw_list') };

		so = ss.option(form.DummyValue, '_china_list_version', _('China list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'china_list') };
		/* Overview END */

		/* General START */
		s.tab('general', _('General'));

		/* General settings */
		o = s.taboption('general', form.SectionValue, '_global', form.NamedSection, 'global', 'fchomo', _('General settings'));
		ss = o.subsection;

		so = ss.option(form.ListValue, 'mode', _('Operation mode'));
		so.value('direct', _('Direct'));
		so.value('rule', _('Rule'));
		so.value('global', _('Global'));
		so.default = 'rule';

		so = ss.option(form.ListValue, 'find_process_mode', _('Process matching mode'));
		so.value('always', _('Enable'));
		so.value('strict', _('Auto'));
		so.value('off', _('Disable'));
		so.default = 'off';

		so = ss.option(form.ListValue, 'log_level', _('Log level'));
		so.value('silent', _('Silent'));
		so.value('error', _('Error'));
		so.value('warning', _('Warning'));
		so.value('info', _('Info'));
		so.value('debug', _('Debug'));
		so.default = 'warning';

		so = ss.option(form.Flag, 'etag_support', _('ETag support'));
		so.default = so.enabled;

		so = ss.option(form.Flag, 'ipv6', _('IPv6 support'));
		so.default = so.enabled;

		so = ss.option(form.Flag, 'unified_delay', _('Unified delay'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'tcp_concurrent', _('TCP concurrency'));
		so.default = so.disabled;

		so = ss.option(form.Value, 'keep_alive_interval', _('TCP-Keep-Alive interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('30'));
		so.placeholder = '30';
		so.validate = L.bind(hm.validateTimeDuration, so);

		so = ss.option(form.Value, 'keep_alive_idle', _('TCP-Keep-Alive idle timeout'),
			_('In seconds. <code>%s</code> will be used if empty.').format('600'));
		so.placeholder = '600';
		so.validate = L.bind(hm.validateTimeDuration, so);

		/* Global Authentication */
		o = s.taboption('general', form.SectionValue, '_global', form.NamedSection, 'global', 'fchomo', _('Global Authentication'));
		ss = o.subsection;

		so = ss.option(form.DynamicList, 'authentication', _('User Authentication'));
		so.datatype = 'list(string)';
		so.placeholder = 'user1:pass1';
		so.validate = L.bind(hm.validateAuth, so);

		so = ss.option(form.DynamicList, 'skip_auth_prefixes', _('No Authentication IP ranges'));
		so.datatype = 'list(cidr)';
		so.placeholder = '127.0.0.1/8';
		/* General END */

		/* Inbound START */
		s.tab('inbound', _('Inbound'));

		/* Listen ports */
		o = s.taboption('inbound', form.SectionValue, '_inbound', form.NamedSection, 'inbound', 'fchomo', _('Listen ports'));
		ss = o.subsection;

		so = ss.option(form.Value, 'mixed_port', _('Mixed port'));
		so.datatype = 'port';
		so.placeholder = '7890';
		so.rmempty = false;

		so = ss.option(form.Value, 'redir_port', _('Redir port'));
		so.datatype = 'port';
		so.placeholder = '7891';
		so.rmempty = false;

		so = ss.option(form.Value, 'tproxy_port', _('Tproxy port'));
		so.datatype = 'port';
		so.placeholder = '7892';
		so.rmempty = false;

		so = ss.option(form.Value, 'tunnel_port', _('DNS port'));
		so.datatype = 'port';
		so.placeholder = '7893';
		so.rmempty = false;

		so = ss.option(form.ListValue, 'proxy_mode', _('Proxy mode'));
		so.value('redir', _('Redirect TCP'));
		if (features.hm_has_tproxy)
			so.value('redir_tproxy', _('Redirect TCP + TProxy UDP'));
		if (features.hm_has_ip_full && features.hm_has_tun) {
			so.value('redir_tun', _('Redirect TCP + Tun UDP'));
			so.value('tun', _('Tun TCP/UDP'));
		} else
			so.description = _('To enable Tun support, you need to install <code>ip-full</code> and <code>kmod-tun</code>');
		so.default = 'redir_tproxy';
		so.rmempty = false;

		/* Tun settings */
		o = s.taboption('inbound', form.SectionValue, '_inbound', form.NamedSection, 'inbound', 'fchomo', _('Tun settings'));
		ss = o.subsection;

		so = ss.option(form.ListValue, 'tun_stack', _('Stack'),
			_('Tun stack.'));
		so.value('system', _('System'));
		if (features.with_gvisor) {
			so.value('gvisor', _('gVisor'));
			so.value('mixed', _('Mixed'));
		}
		so.default = 'system';
		so.rmempty = false;
		so.onchange = function(ev, section_id, value) {
			var desc = ev.target.nextSibling;
			if (value === 'mixed')
				desc.innerHTML = _('Mixed <code>system</code> TCP stack and <code>gVisor</code> UDP stack.');
			else if (value === 'gvisor')
				desc.innerHTML = _('Based on google/gvisor.');
			else if (value === 'system')
				desc.innerHTML = _('Less compatibility and sometimes better performance.');
		}

		so = ss.option(form.Value, 'tun_mtu', _('MTU'));
		so.datatype = 'uinteger';
		so.placeholder = '9000';

		so = ss.option(form.Flag, 'tun_gso', _('Generic segmentation offload'));
		so.default = so.disabled;

		so = ss.option(form.Value, 'tun_gso_max_size', _('Segment maximum size'));
		so.datatype = 'uinteger';
		so.placeholder = '65536';

		so = ss.option(form.Value, 'tun_udp_timeout', _('UDP NAT expiration time'),
			_('In seconds. <code>%s</code> will be used if empty.').format('300'));
		so.placeholder = '300';
		so.validate = L.bind(hm.validateTimeDuration, so);

		so = ss.option(form.Flag, 'tun_endpoint_independent_nat', _('Endpoint-Independent NAT'),
			_('Performance may degrade slightly, so it is not recommended to enable on when it is not needed.'));
		so.default = so.disabled;
		/* Inbound END */

		/* TLS START */
		s.tab('tls', _('TLS'));

		/* TLS settings */
		o = s.taboption('tls', form.SectionValue, '_tls', form.NamedSection, 'tls', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.ListValue, 'global_client_fingerprint', _('Global client fingerprint'));
		so.default = hm.tls_client_fingerprints[0][0];
		hm.tls_client_fingerprints.forEach((res) => {
			so.value.apply(so, res);
		})

		so = ss.option(form.Value, 'tls_cert_path', _('API TLS certificate path'));
		so.datatype = 'file';
		so.value('/etc/ssl/acme/example.crt');

		so = ss.option(form.Value, 'tls_key_path', _('API TLS private key path'));
		so.datatype = 'file';
		so.value('/etc/ssl/acme/example.key');
		/* TLS END */

		/* API START */
		s.tab('api', _('API'));

		/* API settings */
		o = s.taboption('api', form.SectionValue, '_api', form.NamedSection, 'api', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.ListValue, 'dashboard_repo', _('Select Dashboard'));
		so.default = hm.dashrepos[0][0];
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			this.value('', _('-- Please choose --'));
			hm.dashrepos.forEach((repo) => {
				L.resolveDefault(callResVersion('dashboard', repo[0]), {}).then((res) => {
					this.value(repo[0], repo[1] + ' - ' + (res.version || _('Not Installed')));
				});
			});

			return this.super('load', section_id);
		}
		so.rmempty = false;

		so = ss.option(form.DynamicList, 'external_controller_cors_allow_origins', _('CORS Allow origins'),
			_('CORS allowed origins, <code>*</code> will be used if empty.'));
		so.placeholder = 'https://yacd.metacubex.one';

		so = ss.option(form.Flag, 'external_controller_cors_allow_private_network', _('CORS Allow private network'),
			_('Allow access from private network.</br>' +
			'To access the API on a private network from a public website, it must be enabled.'));
		so.default = so.enabled;

		so = ss.option(form.Value, 'external_controller_port', _('API HTTP port'));
		so.datatype = 'port';
		so.placeholder = '9090';

		so = ss.option(form.Value, 'external_controller_tls_port', _('API HTTPS port'));
		so.datatype = 'port';
		so.placeholder = '9443';
		so.depends({'fchomo.tls.tls_cert_path': /^\/.+/, 'fchomo.tls.tls_key_path': /^\/.+/});

		so = ss.option(form.Value, 'external_doh_server', _('API DoH service'));
		so.placeholder = '/dns-query';
		so.depends({'external_controller_tls_port': /\d+/});

		so = ss.option(form.Value, 'secret', _('API secret'),
			_('Random will be used if empty.'));
		so.password = true;
		/* API END */

		/* Sniffer START */
		s.tab('sniffer', _('Sniffer'));

		/* Sniffer settings */
		o = s.taboption('sniffer', form.SectionValue, '_sniffer', form.NamedSection, 'sniffer', 'fchomo', _('Sniffer settings'));
		ss = o.subsection;

		so = ss.option(form.Flag, 'override_destination', _('Override destination'),
			_('Override the connection destination address with the sniffed domain.'));
		so.default = so.enabled;

		so = ss.option(form.DynamicList, 'force_domain', _('Forced sniffing domain'));
		so.datatype = 'list(string)';

		so = ss.option(form.DynamicList, 'skip_domain', _('Skiped sniffing domain'));
		so.datatype = 'list(string)';

		so = ss.option(form.DynamicList, 'skip_src_address', _('Skiped sniffing src address'));
		so.datatype = 'list(cidr)';

		so = ss.option(form.DynamicList, 'skip_dst_address', _('Skiped sniffing dst address'));
		so.datatype = 'list(cidr)';

		/* Sniff protocol settings */
		o = s.taboption('sniffer', form.SectionValue, '_sniffer_sniff', form.GridSection, 'sniff', _('Sniff protocol'));
		ss = o.subsection;
		ss.anonymous = true;
		ss.addremove = false;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.ListValue, 'protocol', _('Protocol'));
		so.value('HTTP');
		so.value('TLS');
		so.value('QUIC');
		so.readonly = true;

		so = ss.option(form.DynamicList, 'ports', _('Ports'));
		so.datatype = 'list(or(port, portrange))';

		so = ss.option(form.Flag, 'override_destination', _('Override destination'));
		so.default = so.enabled;
		so.editable = true;
		/* Sniffer END */

		/* Experimental START */
		s.tab('experimental', _('Experimental'));

		/* Experimental settings */
		o = s.taboption('experimental', form.SectionValue, '_experimental', form.NamedSection, 'experimental', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.Flag, 'quic_go_disable_gso', _('quic-go-disable-gso'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'quic_go_disable_ecn', _('quic-go-disable-ecn'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'dialer_ip4p_convert', _('dialer-ip4p-convert'));
		so.default = so.disabled;
		/* Experimental END */

		/* ACL START */
		s.tab('control', _('Access Control'));

		/* Access Control settings */
		o = s.taboption('control', form.SectionValue, '_control', form.NamedSection, 'routing', 'fchomo', null);
		ss = o.subsection;

		/* Interface control */
		ss.tab('interface', _('Interface Control'));

		so = ss.taboption('interface', widgets.DeviceSelect, 'listen_interfaces', _('Listen interfaces'),
			_('Only process traffic from specific interfaces. Leave empty for all.'));
		so.multiple = true;
		so.noaliases = true;

		so = ss.taboption('interface', widgets.DeviceSelect, 'bind_interface', _('Bind interface'),
			_('Bind outbound traffic to specific interface. Leave empty to auto detect.</br>') +
			_('Priority: Proxy Node > Proxy Group > Global.'));
		so.multiple = false;
		so.noaliases = true;

		so = ss.taboption('interface', form.Value, 'route_table_id', _('Routing table ID'));
		so.ucisection = 'config';
		so.datatype = 'uinteger';
		so.placeholder = '2022';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'route_rule_pref', _('Routing rule priority'));
		so.ucisection = 'config';
		so.datatype = 'uinteger';
		so.placeholder = '9000';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'self_mark', _('Routing mark'),
			_('Priority: Proxy Node > Proxy Group > Global.'));
		so.ucisection = 'config';
		so.datatype = 'uinteger';
		so.placeholder = '200';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'tproxy_mark', _('Tproxy Fwmark'));
		so.ucisection = 'config';
		so.placeholder = '201 or 0xc9/0xff';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'tun_mark', _('Tun Fwmark'));
		so.ucisection = 'config';
		so.placeholder = '202 or 0xca/0xff';
		so.rmempty = false;

		/* Access control */
		ss.tab('access_control', _('Access Control'));

		so = ss.taboption('access_control', form.ListValue, 'lan_filter', _('Users filter mode'));
		so.value('', _('All allowed'));
		so.value('white_list', _('White list'));
		so.value('black_list', _('Black list'));

		so = fwtool.addIPOption(ss, 'access_control', 'lan_direct_ipv4_ips', _('Direct IPv4 IP-s'), null, 'ipv4', hosts, true);
		so.depends('lan_filter', 'black_list');

		so = fwtool.addIPOption(ss, 'access_control', 'lan_direct_ipv6_ips', _('Direct IPv6 IP-s'), null, 'ipv6', hosts, true);
		so.depends({'lan_filter': 'black_list', 'fchomo.global.ipv6': '1'});

		so = fwtool.addMACOption(ss, 'access_control', 'lan_direct_mac_addrs', _('Direct MAC-s'), null, hosts);
		so.depends('lan_filter', 'black_list');

		so = fwtool.addIPOption(ss, 'access_control', 'lan_proxy_ipv4_ips', _('Proxy IPv4 IP-s'), null, 'ipv4', hosts, true);
		so.depends('lan_filter', 'white_list');

		so = fwtool.addIPOption(ss, 'access_control', 'lan_proxy_ipv6_ips', _('Proxy IPv6 IP-s'), null, 'ipv6', hosts, true);
		so.depends({'lan_filter': 'white_list', 'fchomo.global.ipv6': '1'});

		so = fwtool.addMACOption(ss, 'access_control', 'lan_proxy_mac_addrs', _('Proxy MAC-s'), null, hosts);
		so.depends('lan_filter', 'white_list');

		so = ss.taboption('access_control', form.Flag, 'proxy_router', _('Proxy routerself'));
		so.default = so.enabled;

		/* Routing control */
		ss.tab('routing_control', _('Routing Control'));

		so = ss.taboption('routing_control', form.Value, 'routing_tcpport', _('Routing ports') + ' (TCP)',
			_('Specify target ports to be proxied. Multiple ports must be separated by commas.'));
		so.value('', _('All ports'));
		so.value('common', _('Common ports only (bypass P2P traffic)'));
		so.value('common_stun', _('Common and STUN ports'));
		so.validate = L.bind(hm.validateCommonPort, so);

		so = ss.taboption('routing_control', form.Value, 'routing_udpport', _('Routing ports') + ' (UDP)',
			_('Specify target ports to be proxied. Multiple ports must be separated by commas.'));
		so.value('', _('All ports'));
		so.value('common', _('Common ports only (bypass P2P traffic)'));
		so.value('common_stun', _('Common and STUN ports'));
		so.validate = L.bind(hm.validateCommonPort, so);

		so = ss.taboption('routing_control', form.ListValue, 'routing_mode', _('Routing mode'),
			_('Routing mode of the traffic enters mihomo via firewall rules.'));
		so.value('', _('All allowed'));
		so.value('bypass_cn', _('Bypass CN'));
		so.value('routing_gfw', _('Routing GFW'));

		so = ss.taboption('routing_control', form.Flag, 'routing_domain', _('Handle domain'),
			_('Routing mode will be handle domain.'));
		so.default = so.disabled;
		if (!features.hm_has_dnsmasq_full) {
			so.description = _('To enable, you need to install <code>dnsmasq-full</code>.');
			so.readonly = true;
			uci.set(data[0], so.section.section, so.option, '');
			uci.save();
		}
		so.depends('routing_mode', 'bypass_cn');
		so.depends('routing_mode', 'routing_gfw');

		/* Custom Direct list */
		ss.tab('direct_list', _('Custom Direct List'));

		so = ss.taboption('direct_list', form.TextValue, 'direct_list.yaml', null);
		so.renderWidget = function(/* ... */) {
			var frameEl = form.TextValue.prototype.renderWidget.apply(this, arguments);

			frameEl.firstChild.style.fontFamily = hm.monospacefonts.join(',');

			return frameEl;
		}
		so.rows = 20;
		so.default = 'FQDN:\nIPCIDR:\nIPCIDR6:\n';
		so.placeholder = "FQDN:\n- mask.icloud.com\n- mask-h2.icloud.com\n- mask.apple-dns.net\nIPCIDR:\n- '223.0.0.0/12'\nIPCIDR6:\n- '2400:3200::/32'\n";
		so.load = function(section_id) {
			return L.resolveDefault(hm.readFile('resources', this.option), '');
		}
		so.write = function(section_id, formvalue) {
			return hm.writeFile('resources', this.option, formvalue);
		}
		so.remove = function(section_id) {
			return hm.writeFile('resources', this.option);
		}
		so.rmempty = false;

		/* Custom Proxy list */
		ss.tab('proxy_list', _('Custom Proxy List'));

		so = ss.taboption('proxy_list', form.TextValue, 'proxy_list.yaml', null);
		so.renderWidget = function(/* ... */) {
			var frameEl = form.TextValue.prototype.renderWidget.apply(this, arguments);

			frameEl.firstChild.style.fontFamily = hm.monospacefonts.join(',');

			return frameEl;
		}
		so.rows = 20;
		so.default = 'FQDN:\nIPCIDR:\nIPCIDR6:\n';
		so.placeholder = "FQDN:\n- www.google.com\nIPCIDR:\n- '91.105.192.0/23'\nIPCIDR6:\n- '2001:67c:4e8::/48'\n";
		so.load = function(section_id) {
			return L.resolveDefault(hm.readFile('resources', this.option), '');
		}
		so.write = function(section_id, formvalue) {
			return hm.writeFile('resources', this.option, formvalue);
		}
		so.remove = function(section_id) {
			return hm.writeFile('resources', this.option);
		}
		so.rmempty = false;
		/* ACL END */

		return m.render();
	}
});
