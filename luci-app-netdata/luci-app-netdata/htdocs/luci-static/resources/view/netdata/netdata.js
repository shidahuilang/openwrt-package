// Copyright (C) 2021-2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netdata
'use strict';
'require view';
'require fs';
'require ui';
'require uci';
'require form';
'require poll';

return view.extend({

    load: function() {
        return uci.load('netdata');
    },

    checkRunning: function() {
        return fs.exec('/bin/pidof', ['netdata']).then(function(pidRes) {
            if (pidRes.code === 0) return { isRunning: true };
            return fs.exec('/bin/ash', ['-c', 'ps | grep -q "[n]etdata"']).then(function(grepRes) {
                return { isRunning: grepRes.code === 0 };
            });
        });
    },
    
    render: function() {
        var self = this;
        return this.checkRunning().then(function(checkResult) {
            var isRunning = checkResult.isRunning;
            let webport = uci.get_first('netdata', 'netdata', 'port') || '19999';
            let uci_ssl = uci.get_first('netdata', 'netdata', 'enable_ssl') || '0';
            let nginx = uci.get_first('netdata', 'netdata', 'nginx_support') || '0';
            let protocol = nginx === '1' ? window.location.protocol : uci_ssl === '1' ? 'https:' : 'http:';
            let buttonUrl = String.format('%s//%s:%s/', protocol, window.location.hostname, webport);
            
            var container = E('div');
            if (!isRunning) { 
                var message = _('Netdata Service Not Running');
                container.appendChild(E('div', { 
                    style: 'text-align: center; padding: 2em;' 
                }, [
                    E('img', {
                        src: 'data:image/svg+xml;base64,PHN2ZyB2ZXJzaW9uPSIxLjEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMjQiIGhlaWdodD0iMTAyNCIgdmlld0JveD0iMCAwIDEwMjQgMTAyNCI+PHBhdGggZmlsbD0iI2RmMDAwMCIgZD0iTTk0Mi40MjEgMjM0LjYyNGw4MC44MTEtODAuODExLTE1My4wNDUtMTUzLjA0NS04MC44MTEgODAuODExYy03OS45NTctNTEuNjI3LTE3NS4xNDctODEuNTc5LTI3Ny4zNzYtODEuNTc5LTI4Mi43NTIgMC01MTIgMjI5LjI0OC01MTIgNTEyIDAgMTAyLjIyOSAyOS45NTIgMTk3LjQxOSA4MS41NzkgMjc3LjM3NmwtODAuODExIDgwLjgxMSAxNTMuMDQ1IDE1My4wNDUgODAuODExLTgwLjgxMWM3OS45NTcgNTEuNjI3IDE3NS4xNDcgODEuNTc5IDI3Ny4zNzYgODEuNTc5IDI4Mi43NTIgMCA1MTItMjI5LjI0OCA1MTItNTEyIDAtMTAyLjIyOS0yOS45NTItMTk3LjQxOS04MS41NzktMjc3LjM3NnpNMTk0Ljk0NCA1MTJjMC0xNzUuMTA0IDE0MS45NTItMzE3LjA1NiAzMTcuMDU2LTMxNy4wNTYgNDggMCA5My40ODMgMTAuNjY3IDEzNC4yMjkgMjkuNzgxbC00MjEuNTQ3IDQyMS41NDdjLTE5LjA3Mi00MC43ODktMjkuNzM5LTg2LjI3Mi0yOS43MzktMTM0LjI3MnpNNTEyIDgyOS4wNTZjLTQ4IDAtOTMuNDgzLTEwLjY2Ny0xMzQuMjI5LTI5Ljc4MWw0MjEuNTQ3LTQyMS41NDdjMTkuMDcyIDQwLjc4OSAyOS43ODEgODYuMjcyIDI5Ljc4MSAxMzQuMjI5LTAuMDQzIDE3NS4xNDctMTQxLjk5NSAzMTcuMDk5LTMxNy4wOTkgMzE3LjA5OXoiLz48L3N2Zz4=',
                        style: 'width: 100px; height: 100px; margin-bottom: 1em;'
                    }),
                    E('h2', {}, message)
                ]));
            } else {
                var iframe = E('iframe', {
                    src: buttonUrl,
                    style: 'width: 100%; min-height: 100vh; border: none;'
                });
                container.appendChild(iframe);
            }

            poll.add(function() {
                return self.checkRunning().then(function(checkResult) {
                    var newStatus = checkResult.isRunning;
                    if (newStatus !== isRunning) {
                        window.location.reload();
                    }
                });
            }, 5);
            
            poll.start();
            
            return container;
        });
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});