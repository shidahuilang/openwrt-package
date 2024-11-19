'use strict';
'require form';
'require uci';
'require ui';
'require view';

'require fchomo as hm';

function parseRulesetLink(uri) {
	var config,
		filefmt = new RegExp(/^(text|yaml|mrs)$/),
		filebehav = new RegExp(/^(domain|ipcidr|classical)$/),
		unuciname = new RegExp(/[^a-zA-Z0-9_]+/, "g");

	uri = uri.split('://');
	if (uri[0] && uri[1]) {
		switch (uri[0]) {
		case 'http':
		case 'https':
			var url = new URL('http://' + uri[1]);
			var format = url.searchParams.get('fmt');
			var behavior = url.searchParams.get('behav');
			var interval = url.searchParams.get('sec');
			var rawquery = url.searchParams.get('rawq');
			var name = decodeURI(url.pathname).split('/').pop()
				.replace(/[\s\.-]/g, '_').replace(unuciname, '');

			if (filefmt.test(format) && filebehav.test(behavior)) {
				var fullpath = (url.username ? url.username + '@' : '') + url.host + url.pathname + (rawquery ? '?' + decodeURIComponent(rawquery) : '');
				config = {
					label: url.hash ? decodeURIComponent(url.hash.slice(1)) : name ? name : null,
					type: 'http',
					format: format,
					behavior: behavior,
					url: String.format('%s://%s', uri[0], fullpath),
					interval: interval,
					href: hm.calcStringMD5(String.format('http://%s', fullpath))
				};
			}

			break;
		case 'file':
			var url = new URL('file://' + uri[1]);
			var format = url.searchParams.get('fmt');
			var behavior = url.searchParams.get('behav');
			var filler = url.searchParams.get('fill');
			var path = decodeURI(url.pathname);
			var name = path.split('/').pop()
				.replace(/[\s\.-]/g, '_').replace(unuciname, '');

			if (filefmt.test(format) && filebehav.test(behavior)) {
				config = {
					label: url.hash ? decodeURIComponent(url.hash.slice(1)) : name ? name : null,
					type: 'file',
					format: format,
					behavior: behavior,
					href: hm.calcStringMD5(String.format('file://%s%s', url.host, url.pathname))
				};
				hm.writeFile('ruleset', config.href, hm.decodeBase64Str(filler));
			}

			break;
		}
	}

	if (config) {
		if (!config.type || !config.href)
			return null;
		else if (!config.label)
			config.label = hm.calcStringMD5(config.href);
	}

	return config;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('fchomo')
		]);
	},

	render: function(data) {
		var m, s, o;

		m = new form.Map('fchomo', _('Edit ruleset'));

		/* Rule set START */
		/* Rule set settings */
		var prefmt = { 'prefix': 'rule_', 'suffix': '' };
		s = m.section(form.GridSection, 'ruleset');
		s.addremove = true;
		s.rowcolors = true;
		s.sortable = true;
		s.nodescriptions = true;
		s.modaltitle = L.bind(hm.loadModalTitle, s, _('Rule set'), _('Add a rule set'));
		s.sectiontitle = L.bind(hm.loadDefaultLabel, s);
		/* Import rule-set links and Remove idle files start */
		s.handleLinkImport = function() {
			var textarea = new ui.Textarea('', {
				'placeholder': 'http(s)://github.com/ACL4SSR/ACL4SSR/raw/refs/heads/master/Clash/Providers/BanAD.yaml?fmt=yaml&behav=classical&rawq=good%3Djob#BanAD\n' +
							   'file:///example.txt?fmt=text&behav=domain&fill=LmNuCg#CN%20TLD\n'
			});
			ui.showModal(_('Import rule-set links'), [
				E('p', _('Supports rule-set links of type: <code>file, http</code> and format: <code>text, yaml, mrs</code>.</br>') +
							_('Please refer to <a href="%s" target="_blank">%s</a> for link format standards.')
								.format(hm.rulesetdoc, _('Ruleset-URI-Scheme'))),
				textarea.render(),
				E('div', { class: 'right' }, [
					E('button', {
						class: 'btn',
						click: ui.hideModal
					}, [ _('Cancel') ]),
					' ',
					E('button', {
						class: 'btn cbi-button-action',
						click: ui.createHandlerFn(this, function() {
							var input_links = textarea.getValue().trim().split('\n');
							if (input_links && input_links[0]) {
								/* Remove duplicate lines */
								input_links = input_links.reduce((pre, cur) =>
									(!pre.includes(cur) && pre.push(cur), pre), []);

								var imported_ruleset = 0;
								input_links.forEach((l) => {
									var config = parseRulesetLink(l);
									if (config) {
										var sid = uci.add(data[0], 'ruleset', config.href);
										config.href = null;
										Object.keys(config).forEach((k) => {
											uci.set(data[0], sid, k, config[k] || '');
										});
										imported_ruleset++;
									}
								});

								if (imported_ruleset === 0)
									ui.addNotification(null, E('p', _('No valid rule-set link found.')));
								else
									ui.addNotification(null, E('p', _('Successfully imported %s rule-set of total %s.').format(
										imported_ruleset, input_links.length)));

								return uci.save()
									.then(L.bind(this.map.load, this.map))
									.then(L.bind(this.map.reset, this.map))
									.then(L.ui.hideModal)
									.catch(function() {});
							} else {
								return ui.hideModal();
							}
						})
					}, [ _('Import') ])
				])
			])
		}
		s.renderSectionAdd = function(/* ... */) {
			var el = hm.renderSectionAdd.apply(this, [prefmt, false].concat(Array.prototype.slice.call(arguments)));

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('Import rule-set links'),
				'click': ui.createHandlerFn(this, 'handleLinkImport')
			}, [ _('Import rule-set links') ]));

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('Remove idles'),
				'click': ui.createHandlerFn(this, hm.handleRemoveIdles, hm)
			}, [ _('Remove idles') ]));

			return el;
		}
		s.handleAdd = L.bind(hm.handleAdd, s, prefmt);
		/* Import rule-set links and Remove idle files end */

		o = s.option(form.Value, 'label', _('Label'));
		o.load = L.bind(hm.loadDefaultLabel, o);
		o.validate = L.bind(hm.validateUniqueValue, o);
		o.modalonly = true;

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.enabled;
		o.editable = true;

		o = s.option(form.ListValue, 'type', _('Type'));
		o.value('file', _('Local'));
		o.value('http', _('Remote'));
		o.default = 'http';

		o = s.option(form.ListValue, 'format', _('Format'));
		o.value('text', _('Plain text'));
		o.value('yaml', _('Yaml text'));
		o.value('mrs', _('Binary file'));
		o.default = 'mrs';
		o.validate = function(section_id, value) {
			var behavior = this.section.getUIElement(section_id, 'behavior').getValue();

			if (value === 'mrs' && behavior === 'classical')
				return _('Expecting: %s').format(_('Binary format only supports domain / ipcidr'));

			return true;
		}

		o = s.option(form.ListValue, 'behavior', _('Behavior'));
		o.value('classical');
		o.value('domain');
		o.value('ipcidr');
		o.default = 'classical';
		o.validate = function(section_id, value) {
			var format = this.section.getUIElement(section_id, 'format').getValue();

			if (value === 'classical' && format === 'mrs')
				return _('Expecting: %s').format(_('Binary format only supports domain / ipcidr'));

			return true;
		}

		o = s.option(form.DummyValue, '_value', _('Value'));
		o.load = function(section_id) {
			var option = uci.get(data[0], section_id, 'type');

			switch (option) {
				case 'file':
					return uci.get(data[0], section_id, '.name');
				case 'http':
					return uci.get(data[0], section_id, 'url');
				default:
					return null;
			}
		}
		o.modalonly = false;

		o = s.option(form.TextValue, '_editer', _('Editer'),
			_('Please type <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/rule-providers/content/', _('Contents')));
		o.renderWidget = function(/* ... */) {
			var frameEl = form.TextValue.prototype.renderWidget.apply(this, arguments);

			frameEl.firstChild.style.fontFamily = hm.monospacefonts.join(',');

			return frameEl;
		}
		o.placeholder = _('Content will not be verified, Please make sure you enter it correctly.');
		o.load = function(section_id) {
			return L.resolveDefault(hm.readFile('ruleset', section_id), '');
		}
		o.write = L.bind(hm.writeFile, o, 'ruleset');
		o.remove = L.bind(hm.writeFile, o, 'ruleset');
		o.rmempty = false;
		o.retain = true;
		o.depends({'type': 'file', 'format': /^(text|yaml)$/});
		o.modalonly = true;

		o = s.option(form.Value, 'url', _('Rule set URL'));
		o.validate = L.bind(hm.validateUrl, o);
		o.rmempty = false;
		o.depends('type', 'http');
		o.modalonly = true;

		o = s.option(form.Value, 'interval', _('Update interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('259200'));
		o.placeholder = '259200';
		o.validate = L.bind(hm.validateTimeDuration, o);
		o.depends('type', 'http');

		o = s.option(form.ListValue, 'proxy', _('Proxy group'),
			_('Name of the Proxy group to download rule set.'));
		o.default = hm.preset_outbound.direct[0][0];
		hm.preset_outbound.direct.forEach((res) => {
			o.value.apply(o, res);
		})
		o.load = L.bind(hm.loadProxyGroupLabel, o, hm.preset_outbound.direct);
		o.textvalue = L.bind(hm.textvalue2Value, o);
		//o.editable = true;
		o.depends('type', 'http');

		o = s.option(form.DummyValue, '_update');
		o.cfgvalue = L.bind(hm.renderResDownload, o, hm);
		o.editable = true;
		o.modalonly = false;
		/* Rule set END */

		return m.render();
	}
});
