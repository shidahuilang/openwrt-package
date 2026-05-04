'use strict';
'require dom';
'require fs';
'require poll';
'require view';
'require rpc';
'require ui';

const callPrintLog = rpc.declare({
	object: 'luci.mosdns',
	method: 'print_log',
	expect: { '': {} }
});

const callCleanLog = rpc.declare({
	object: 'luci.mosdns',
	method: 'clean_log',
	expect: { '': {} }
});

let scrollPosition = 0;
let userScrolled = false;
let logTextarea;

function pollLog() {
	return callPrintLog().then(res => {
		logTextarea.value = res.log || _('No log data.');

		if (!userScrolled) {
			logTextarea.scrollTop = logTextarea.scrollHeight;
		} else {
			logTextarea.scrollTop = scrollPosition;
		}
	});
}

return view.extend({
	handleCleanLogs() {
		return callCleanLog().then(res => {
			if (res.success) {
				logTextarea.value = ''; // Clear textarea on success
			} else {
				ui.addNotification(null, E('p', _('Failed to clean logs.') + (res.error ? ': ' + res.error : '')), 'error');
			}
		}).catch(e => ui.addNotification(null, E('p', e.message)));
	},

	render() {
		logTextarea = E('textarea', {
			'class': 'cbi-input-textarea',
			'wrap': 'off',
			'readonly': 'readonly',
			'style': 'width: calc(100% - 20px);height: 535px;margin: 10px;overflow-y: scroll;',
		});

		logTextarea.addEventListener('scroll', () => {
			userScrolled = true;
			scrollPosition = logTextarea.scrollTop;
		});

		const log_textarea_wrapper = E('div', { 'id': 'log_textarea' }, logTextarea);

		poll.add(pollLog);

		const clear_logs_button = E('input', { 'class': 'btn cbi-button-action', 'type': 'button', 'style': 'margin-left: 10px; margin-top: 10px;', 'value': _('Clear logs') });
		clear_logs_button.addEventListener('click', this.handleCleanLogs.bind(this));

		return E([
			E('div', { 'class': 'cbi-map' }, [
				E('h2', { 'name': 'content' }, '%s - %s'.format(_('MosDNS'), _('Log Data'))),
				E('div', { 'class': 'cbi-section' }, [
					clear_logs_button,
					log_textarea_wrapper,
					E('div', { 'style': 'text-align:right' },
						E('small', {}, _('Refresh every %s seconds.').format(L.env.pollinterval))
					)
				])
			])
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
