'use strict';
'require view.log-viewer.multilog.abstract-multilog as abc';

return abc.view.extend({
	viewName: 'multilog-messages',
	title   : _('Log') + ' - ' + _('messages'),
	logFile : '/var/log/messages',
});
