'use strict';
'require view';
'require dom';
'require fs';
'require ui';
'require uci';
'require network';
'require rpc';
'require tools.github as github';

return view.extend({
    load: function() {
        return L.resolveDefault(fs.list('/tmp/yt-dlp/'), null);
    },

    updateTable: function(table, files) {
        var rows = [];
        
        if (files == null)
            return;

        for(var i = 0; i < files.length; i++) {
            var file = files[i];

            rows.push([
                file.name,
                file.size,
                E('span', { 'class': 'diag-action' }, [
                    E('button', {
                        'class': 'cbi-button cbi-button-action important',
                        'click': ui.createHandlerFn(this, 'handleDownloadVideo', file.name)
                    }, _('Download')),
                    E('button', {
                        'class': 'cbi-button cbi-button-action cbi-button-negative',
                        'click': ui.createHandlerFn(this, 'handleDeleteVideo', file.name)
                    }, _('Delete'))
                ]),
            ]);
        }

        cbi_update_table(table, rows, E('em', _('No information available')));
    },

    handleYtdlp: function(ev) {
        var exec = '/usr/bin/yt-dlp',
            addr = ev.currentTarget.parentNode.previousSibling.value,
            args = ['-o', "/tmp/yt-dlp/%(title)s.%(ext)s", addr];
        
        if (addr == '') {
            ui.addNotification(null, E('p', _('Please enter a valid URL')));
            return;
        }

        var buttons = document.querySelectorAll('.diag-action > .cbi-button');

        for (var i = 0; i < buttons.length; i++)
            buttons[i].setAttribute('disabled', 'true');

        return fs.exec(exec, args).then(L.bind(function(res) {
            var out = document.querySelector('.command-output');
                out.style.display = '';

            dom.content(out, [ res.stdout || '', res.stderr || '' ]);
            if (res.stdout) {
                L.resolveDefault(fs.list('/tmp/yt-dlp/'), null).then(L.bind(function(files) {
                    var table = document.getElementById('videos');
                    this.updateTable('#videos', files);
                }, this));
            }
        }, this)).catch(function(err) {
            ui.addNotification(null, E('p', [ err ]));
            return null
        }).finally(function() {
            for (var i = 0; i < buttons.length; i++)
                buttons[i].removeAttribute('disabled');
        });
    },

    handleDeleteVideo: function(filename, ev) {
        var file = '/tmp/yt-dlp/' + filename;
        return fs.remove(file).then(L.bind(function(res) {
            L.resolveDefault(fs.list('/tmp/yt-dlp/'), null).then(L.bind(function(files) {
                var table = document.getElementById('videos');
                this.updateTable("#videos", files);
            }, this));
        }, this)).catch(function(err) {
            ui.addNotification(null, E('p', [ err ]));
            return null
        });
    },


    handleDownloadVideo: function(filename, ev) {
        var file = '/tmp/yt-dlp/' + filename;
        var form = E('form', {
			'method': 'post',
			'action': L.env.cgi_base + '/cgi-download',
			'enctype': 'application/x-www-form-urlencoded'
		}, [
			E('input', { 'type': 'hidden', 'name': 'sessionid', 'value': rpc.getSessionID() }),
			E('input', { 'type': 'hidden', 'name': 'path',      'value': file }),
			E('input', { 'type': 'hidden', 'name': 'filename',  'value': filename })
		]);

		ev.currentTarget.parentNode.appendChild(form);

		form.submit();
		form.parentNode.removeChild(form);
    },

    clearInput: function(ev) {
        document.getElementById('video_url').value = '';
    },

    render: function(files) {
        var video_url;
        var tbl_videos  = E('table', { 'class': 'table', 'id': 'videos' }, [
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th', 'style': 'width:60%' }, _('Name')),
				E('th', { 'class': 'th', 'style': 'width;20%' }, _('Size')),
				E('th', { 'class': 'th', 'style': 'width:20%' }, _('Action')),
			])
		]);
        var description = github.luci_desc('Download video from Youtube, Facebook, Twitter, etc.', 'liudf0716', 'yt-dlp')
        
        var v = E([], [
            E('h2', {}, [ _('Download Video') ]),
            E('div', { 'class': 'cbi-section-descr' }, description ),
            E('table', { 'class': 'table' }, [
                E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td left' }, [
                        E('input', {
                            'style': 'margin:5px 0; width: 50% !important;',
                            'type': 'text',
                            'id': 'video_url',
                            'value': video_url,
                            'placeholder': _('Enter video URL')
                        }),
                        E('span', { 'class': 'diag-action' }, [
                            E('button', {
                                'class': 'cbi-button cbi-button-action',
                                'click': ui.createHandlerFn(this, 'handleYtdlp')
                            }, [ _('Yt-dlp Online') ])
                        ]),
                        E('span', { 'class': 'diag-action' }, [
                            E('button', {
                                'class': 'cbi-button cbi-button-action cbi-button-negative',
                                'click': ui.createHandlerFn(this, 'clearInput')
                            }, [ _('Clear Input') ])
                        ]),]
                    ),
                ])
            ]),
            E('pre', { 'class': 'command-output', 'style': 'display:none' }),
            E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'left' }, [
					E('h3', _('Download Video Details')),
					tbl_videos
				])
			])
        ]);

        this.updateTable(tbl_videos, files);

        return v;
    },

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
