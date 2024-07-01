'use strict';
'require view';
'require form';
'require uci';
'require rpc';
'require ui';
'require poll';
'require request';
'require dom';
'require fs';

let callPackagelist = rpc.declare({
	object: 'rpc-sys',
	method: 'packagelist',
});

let callSystemBoard = rpc.declare({
	object: 'system',
	method: 'board',
});

let callUpgradeStart = rpc.declare({
	object: 'rpc-sys',
	method: 'upgrade_start',
	params: ['keep'],
});

/**
 * Returns the branch of a given version. This helps to offer upgrades
 * for point releases (aka within the branch).
 *
 * Logic:
 * SNAPSHOT -> SNAPSHOT
 * 21.02-SNAPSHOT -> 21.02
 * 21.02.0-rc1 -> 21.02
 * 19.07.8 -> 19.07
 *
 * @param {string} version
 * Input version from which to determine the branch
 * @returns {string}
 * The determined branch
 */
function get_branch(version) {
	return version.replace('-SNAPSHOT', '').split('.').slice(0, 2).join('.');
}

/**
 * The OpenWrt revision string contains both a hash as well as the number
 * commits since the OpenWrt/LEDE reboot. It helps to determine if a
 * snapshot is newer than another.
 *
 * @param {string} revision
 * Revision string of a OpenWrt device
 * @returns {integer}
 * The number of commits since OpenWrt/LEDE reboot
 */
function get_revision_count(revision) {
	return parseInt(revision.substring(1).split('-')[0]);
}

return view.extend({
	steps: {
		init: [10, _('Received build request')],
		download_imagebuilder: [20, _('Downloading ImageBuilder archive')],
		unpack_imagebuilder: [40, _('Setting Up ImageBuilder')],
		calculate_packages_hash: [60, _('Validate package selection')],
		building_image: [80, _('Generating firmware image')],
	},

	data: {
		url: '',
		revision: '',
		advanced_mode: 0,
		rebuilder: [],
		sha256_unsigned: '',
	},

	firmware: {
		profile: '',
		target: '',
		version: '',
		packages: [],
		diff_packages: true,
		filesystem: '',
	},

	selectImage: function (images) {
		let image;
		for (image of images) {
			if (this.firmware.filesystem == image.filesystem) {
				// x86 images can be combined-efi (EFI) or combined (BIOS)
				if(this.firmware.target.indexOf("x86") != -1) {
					if (this.data.efi && image.type == 'combined-efi') {
						return image;
					} else if (image.type == 'combined') {
						return image;
					}
				} else {
					if (image.type == 'sysupgrade' || image.type == 'combined') {
						return image;
					}
				}
			}
		}
		return null;
	},

	handle200: function (response) {
		response = response.json();
		let image = this.selectImage(response.images);

		if (image.name != undefined) {
			this.data.sha256_unsigned = image.sha256_unsigned;
			let sysupgrade_url = `${this.data.url}/store/${response.request_hash}/${image.name}`;

			let keep = E('input', { type: 'checkbox' });
			keep.checked = true;

			let fields = [
				_('Version'),
				`${response.version_number} ${response.version_code}`,
				_('SHA256'),
				image.sha256,
			];

			if (this.data.advanced_mode == 1) {
				fields.push(
					_('Profile'),
					response.id,
					_('Target'),
					response.target,
					_('Build Date'),
					response.build_at,
					_('Filename'),
					image.name,
					_('Filesystem'),
					image.filesystem
				);
			}

			fields.push(
				'',
				E('a', { href: sysupgrade_url }, _('Download firmware image'))
			);
			if (this.data.rebuilder) {
				fields.push(_('Rebuilds'), E('div', { id: 'rebuilder_status' }));
			}

			let table = E('div', { class: 'table' });

			for (let i = 0; i < fields.length; i += 2) {
				table.appendChild(
					E('tr', { class: 'tr' }, [
						E('td', { class: 'td left', width: '33%' }, [fields[i]]),
						E('td', { class: 'td left' }, [fields[i + 1]]),
					])
				);
			}

			let modal_body = [
				table,
				E(
					'p',
					{ class: 'mt-2' },
					E('label', { class: 'btn' }, [
						keep,
						' ',
						_('Keep settings and retain the current configuration'),
					])
				),
				E('div', { class: 'right' }, [
					E('div', { class: 'btn', click: ui.hideModal }, _('Cancel')),
					' ',
					E(
						'button',
						{
							class: 'btn cbi-button cbi-button-positive important',
							click: ui.createHandlerFn(this, function () {
								this.handleInstall(sysupgrade_url, keep.checked, image.sha256);
							}),
						},
						_('Install firmware image')
					),
				]),
			];

			ui.showModal(_('Successfully created firmware image'), modal_body);
			if (this.data.rebuilder) {
				this.handleRebuilder();
			}
		}
	},

	handle202: function (response) {
		response = response.json();
		this.data.request_hash = response.request_hash;

		if ('queue_position' in response) {
			ui.showModal(_('Queued...'), [
				E(
					'p',
					{ class: 'spinning' },
					_('Request in build queue position %s').format(
						response.queue_position
					)
				),
			]);
		} else {
			ui.showModal(_('Building Firmware...'), [
				E(
					'p',
					{ class: 'spinning' },
					_('Progress: %s%% %s').format(
						this.steps[response.imagebuilder_status][0],
						this.steps[response.imagebuilder_status][1]
					)
				),
			]);
		}
	},

	handleError: function (response) {
		response = response.json();
		let body = [
			E('p', {}, _('Server response: %s').format(response.detail)),
			E(
				'a',
				{ href: 'https://github.com/openwrt/asu/issues' },
				_('Please report the error message and request')
			),
			E('p', {}, _('Request Data:')),
			E('pre', {}, JSON.stringify({ ...this.data, ...this.firmware }, null, 4)),
		];

		if (response.stdout) {
			body.push(E('b', {}, 'STDOUT:'));
			body.push(E('pre', {}, response.stdout));
		}

		if (response.stderr) {
			body.push(E('b', {}, 'STDERR:'));
			body.push(E('pre', {}, response.stderr));
		}

		body = body.concat([
			E('div', { class: 'right' }, [
				E('div', { class: 'btn', click: ui.hideModal }, _('Close')),
			]),
		]);

		ui.showModal(_('Error building the firmware image'), body);
	},

	handleRequest: function (server, main) {
		let request_url = `${server}/api/v1/build`;
		let method = 'POST';
		let content = this.firmware;

		/**
		 * If `request_hash` is available use a GET request instead of
		 * sending the entire object.
		 */
		if (this.data.request_hash && main == true) {
			request_url += `/${this.data.request_hash}`;
			content = {};
			method = 'GET';
		}

		request
			.request(request_url, { method: method, content: content })
			.then((response) => {
				switch (response.status) {
					case 202:
						if (main) {
							this.handle202(response);
						} else {
							response = response.json();

							let view = document.getElementById(server);
							view.innerText = `⏳	(${
								this.steps[response.imagebuilder_status][0]
							}%) ${server}`;
						}
						break;
					case 200:
						if (main == true) {
							poll.remove(this.pollFn);
							this.handle200(response);
						} else {
							poll.remove(this.rebuilder_polls[server]);
							response = response.json();
							let view = document.getElementById(server);
							let image = this.selectImage(response.images);
							if (image.sha256_unsigned == this.data.sha256_unsigned) {
								view.innerText = '✅ %s'.format(server);
							} else {
								view.innerHTML = `⚠️ ${server} (<a href="${server}/store/${
									response.bin_dir
								}/${image.name}">${_('Download')}</a>)`;
							}
						}
						break;
					case 400: // bad request
					case 422: // bad package
					case 500: // build failed
						if (main == true) {
							poll.remove(this.pollFn);
							this.handleError(response);
							break;
						} else {
							poll.remove(this.rebuilder_polls[server]);
							document.getElementById(server).innerText = '🚫 %s'.format(
								server
							);
						}
				}
			});
	},

	handleRebuilder: function () {
		this.rebuilder_polls = {};
		for (let rebuilder of this.data.rebuilder) {
			this.rebuilder_polls[rebuilder] = L.bind(
				this.handleRequest,
				this,
				rebuilder,
				false
			);
			poll.add(this.rebuilder_polls[rebuilder], 5);
			document.getElementById(
				'rebuilder_status'
			).innerHTML += `<p id="${rebuilder}">⏳ ${rebuilder}</p>`;
		}
		poll.start();
	},

	handleInstall: function (url, keep, sha256) {
		ui.showModal(_('Downloading...'), [
			E(
				'p',
				{ class: 'spinning' },
				_('Downloading firmware from server to browser')
			),
		]);

		request
			.get(url, {
				headers: {
					'Content-Type': 'application/x-www-form-urlencoded',
				},
				responseType: 'blob',
			})
			.then((response) => {
				let form_data = new FormData();
				form_data.append('sessionid', rpc.getSessionID());
				form_data.append('filename', '/tmp/firmware.bin');
				form_data.append('filemode', 600);
				form_data.append('filedata', response.blob());

				ui.showModal(_('Uploading...'), [
					E(
						'p',
						{ class: 'spinning' },
						_('Uploading firmware from browser to device')
					),
				]);

				request
					.get(`${L.env.cgi_base}/cgi-upload`, {
						method: 'PUT',
						content: form_data,
					})
					.then((response) => response.json())
					.then((response) => {
						if (response.sha256sum != sha256) {
							ui.showModal(_('Wrong checksum'), [
								E(
									'p',
									_('Error during download of firmware. Please try again')
								),
								E('div', { class: 'btn', click: ui.hideModal }, _('Close')),
							]);
						} else {
							ui.showModal(_('Installing...'), [
								E(
									'p',
									{ class: 'spinning' },
									_('Installing the sysupgrade. Do not unpower device!')
								),
							]);

							L.resolveDefault(callUpgradeStart(keep), {}).then((response) => {
								if (keep) {
									ui.awaitReconnect(window.location.host);
								} else {
									ui.awaitReconnect('192.168.1.1', 'openwrt.lan');
								}
							});
						}
					});
			});
	},

	handleCheck: function (force) {
		let { url, revision } = this.data;
		let { version, target } = this.firmware;
		let candidates = [];
		let request_url = `${url}/api/v1/revision/${version}/${target}`;

		ui.showModal(_('Searching...'), [
			E(
				'p',
				{ class: 'spinning' },
				_('Searching for an available sysupgrade of %s - %s').format(
					version,
					revision
				)
			),
		]);

		L.resolveDefault(request.get(request_url)).then((response) => {
			if (!response.ok) {
				ui.showModal(_('Error connecting to upgrade server'), [
					E(
						'p',
						{},
						_('Could not reach API at "%s". Please try again later.').format(
							response.url
						)
					),
					E('pre', {}, response.responseText),
					E('div', { class: 'right' }, [
						E('div', { class: 'btn', click: ui.hideModal }, _('Close')),
					]),
				]);
				return;
			}
				const remote_revision = response.json().revision;
				if (
					revision < remote_revision || force == 1
				) {
					candidates.push([version, remote_revision]);
				}

			// allow to re-install running firmware in advanced mode
			if (this.data.advanced_mode == 1) {
				candidates.unshift([version, revision]);
			}

			if (candidates.length) {
				let s, o;

				let mapdata = {
					request: {
						profile: this.firmware.profile,
						version: candidates[0][0],
						packages: Object.keys(this.firmware.packages).filter((value) => value.search("-zh-cn") == -1).sort(),
					},
				};

				let map = new form.JSONMap(mapdata, '');

				s = map.section(
					form.NamedSection,
					'request',
					'',
					'',
					'Use defaults for the safest update'
				);
				o = s.option(form.ListValue, 'version', 'Select firmware version');
				for (let candidate of candidates) {
					if (candidate[0] == version && candidate[1] == revision) {
						o.value(
							candidate[0],
							_('[installed] %s').format(
								candidate[1]
									? `${candidate[0]} - ${candidate[1]}`
									: candidate[0]
							)
						);
					} else {
						o.value(
							candidate[0],
							candidate[1] ? `${candidate[0]} - ${candidate[1]}` : candidate[0]
						);
					}
				}

				if (this.data.advanced_mode == 1) {
					o = s.option(form.Value, 'profile', _('Board Name / Profile'));
					o = s.option(form.DynamicList, 'packages', _('Packages'));
				}

				L.resolveDefault(map.render()).then((form_rendered) => {
					ui.showModal(_('New firmware upgrade available'), [
						E(
							'p',
							_('Currently running: %s - %s').format(
								this.firmware.version,
								this.data.revision
							)
						),
						form_rendered,
						E('div', { class: 'right' }, [
							E('div', { class: 'btn', click: ui.hideModal }, _('Cancel')),
							' ',
							E(
								'button',
								{
									class: 'btn cbi-button cbi-button-positive important',
									click: ui.createHandlerFn(this, function () {
										map.save().then(() => {
											this.firmware.packages = mapdata.request.packages;
											this.firmware.version = mapdata.request.version;
											this.firmware.profile = mapdata.request.profile;
											this.pollFn = L.bind(function () {
												this.handleRequest(this.data.url, true);
											}, this);
											poll.add(this.pollFn, 5);
											poll.start();
										});
									}),
								},
								_('Request firmware image')
							),
						]),
					]);
				});
			} else {
				ui.showModal(_('No upgrade available'), [
					E(
						'p',
						_('The device runs the latest firmware version %s - %s').format(
							version,
							revision
						)
					),
					E('div', { class: 'right' }, [
						E('div', { class: 'btn', click: ui.hideModal }, _('Close')),
					E('div', { class: 'btn cbi-button cbi-button-positive', click: ui.createHandlerFn(this, function () {
											this.handleCheck(1)
										}) }, _('Force Sysupgrade')),
					]),
				]);
			}
		});
	},

	load: function () {
		return Promise.all([
			L.resolveDefault(callPackagelist(), {}),
			L.resolveDefault(callSystemBoard(), {}),
			L.resolveDefault(fs.stat('/sys/firmware/efi'), null),
			uci.load('attendedsysupgrade'),
		]);
	},

	render: function (response) {
		this.firmware.client =
			'luci/' + response[0].packages['luci-app-attendedsysupgrade'];
		this.firmware.packages = response[0].packages;

		this.firmware.profile = response[1].board_name;
		this.firmware.target = response[1].release.target;
		this.firmware.version = response[1].release.version;
		this.data.branch = get_branch(response[1].release.version);
		this.firmware.filesystem = response[1].rootfs_type;
		this.data.revision = response[1].release.revision;

		this.data.efi = response[2];
		this.firmware.rootfs_size_mb = Number(response[1].release.distribution);
		if (this.data.efi) {
			this.firmware.efi = "efi";
		} else {
			this.firmware.efi = "not";
		}

		this.data.url = uci.get_first('attendedsysupgrade', 'server', 'url');
		this.data.advanced_mode =
			uci.get_first('attendedsysupgrade', 'client', 'advanced_mode') || 0;
		this.data.rebuilder = uci.get_first(
			'attendedsysupgrade',
			'server',
			'rebuilder'
		);

		return E('p', [
			E('h2', _('Attended Sysupgrade')),
			E(
				'p',
				_(
					'The attended sysupgrade service allows to easily upgrade vanilla and custom firmware images.'
				)
			),
			E(
				'p',
				_(
					'This is done by building a new firmware on demand via an online service.'
				)
			),
			E(
				'p',
				_('Currently running: %s - %s').format(
					this.firmware.version,
					this.data.revision
				)
			),
			E('p', [_('更多个性化定制请使用网页版: '),E('a', {
				'class': '',
				'href': 'https://openwrt.ai',
				'target': '_balank',
			}, _('在线定制网页版'))]),
			E('p', [_('非定制固件请在此更新: '),E('a', {
				'class': '',
				'href': '/cgi-bin/luci/admin/services/gpsysupgrade',
				'target': '_balank',
			}, _('系统在线更新')),E('br')]),
			E(
				'button',
				{
					class: 'btn cbi-button cbi-button-positive important',
					click: ui.createHandlerFn(this, this.handleCheck),
				},
				_('Search for firmware upgrade')
			),
		]);
	},
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,
});
