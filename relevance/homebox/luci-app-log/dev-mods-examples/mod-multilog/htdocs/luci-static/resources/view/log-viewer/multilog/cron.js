'use strict';
'require view.log-viewer.multilog.abstract-multilog as abc';

return abc.view.extend({
	viewName: 'multilog-cron',
	title   : _('Log') + ' - ' + _('cron'),
	logFile : '/var/log/cron',
});
