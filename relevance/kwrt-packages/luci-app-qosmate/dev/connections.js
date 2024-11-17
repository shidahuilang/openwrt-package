'use strict';
'require view';
'require poll';
'require rpc';
'require ui';
'require form';

var callQoSmateConntrackDSCP = rpc.declare({
    object: 'luci.qosmate',
    method: 'getConntrackDSCP',
    expect: { }
});

var dscpToString = function(mark) {
    var dscp = mark & 0x3F;
    var dscpMap = {
        0: 'CS0',
        8: 'CS1',
        10: 'AF11',
        12: 'AF12',
        14: 'AF13',
        16: 'CS2',
        18: 'AF21',
        20: 'AF22',
        22: 'AF23',
        24: 'CS3',
        26: 'AF31',
        28: 'AF32',
        30: 'AF33',
        32: 'CS4',
        34: 'AF41',
        36: 'AF42',
        38: 'AF43',
        40: 'CS5',
        46: 'EF',
        48: 'CS6',
        56: 'CS7'
    };
    return dscpMap[dscp] || dscp.toString();
};

var formatSize = function(bytes) {
    var sizes = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
    if (bytes == 0) return '0 B';
    var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
};

var convertToKbps = function(bytesPerSecond) {
    return (bytesPerSecond * 8 / 1000).toFixed(2) + ' Kbit/s';
};

return view.extend({
    pollInterval: 1,
    lastData: {},
    filter: '',
    sortColumn: 'bytes',
    sortDescending: true,
    connectionHistory: {},
    historyLength: 10,
    lastUpdateTime: 0,

    load: function() {
        return Promise.all([
            callQoSmateConntrackDSCP()
        ]);
    },

    render: function(data) {
        var view = this;
        var connections = [];
        if (data[0] && data[0].connections) {
            connections = Object.values(data[0].connections);
        }

        var filterInput = E('input', {
            'type': 'text',
            'placeholder': _('Filter by IP, IP:Port, Port, Protocol or DSCP'),
            'style': 'margin-bottom: 10px; width: 300px;',
            'value': view.filter
        });

        filterInput.addEventListener('input', function(ev) {
            view.filter = ev.target.value.toLowerCase();
            view.updateTable(connections);
        });

        var table = E('table', { 'class': 'table cbi-section-table', 'id': 'qosmate_connections' }, [
            E('tr', { 'class': 'tr table-titles' }, [
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'protocol') }, [ _('Protocol'), this.createSortIndicator('protocol') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'src') }, [ _('Source'), this.createSortIndicator('src') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'dst') }, [ _('Destination'), this.createSortIndicator('dst') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'dscp') }, [ _('DSCP'), this.createSortIndicator('dscp') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'bytes') }, [ _('Bytes'), this.createSortIndicator('bytes') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'packets') }, [ _('Packets'), this.createSortIndicator('packets') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'avgPps') }, [ _('Avg PPS'), this.createSortIndicator('avgPps') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'maxPps') }, [ _('Max PPS'), this.createSortIndicator('maxPps') ])),
                E('th', { 'class': 'th' }, E('a', { 'href': '#', 'click': this.sortTable.bind(this, 'avgBps') }, [ _('Avg BPS'), this.createSortIndicator('avgBps') ]))
            ])
        ]);

        view.updateTable = function(connections) {
            // Remove all rows except the header
            while (table.rows.length > 1) {
                table.deleteRow(1);
            }
        
            var currentTime = Date.now() / 1000;
            var timeDiff = currentTime - view.lastUpdateTime;
            view.lastUpdateTime = currentTime;
        
            connections.forEach(function(conn) {
                var key = conn.layer3 + conn.protocol + conn.src + conn.sport + conn.dst + conn.dport;
                var lastConn = view.lastData[key];
                
                if (!view.connectionHistory[key]) {
                    view.connectionHistory[key] = {
                        inPpsHistory: [],
                        outPpsHistory: [],
                        inBpsHistory: [],
                        outBpsHistory: [],
                        lastInPackets: conn.in_packets,
                        lastOutPackets: conn.out_packets,
                        lastInBytes: conn.in_bytes,
                        lastOutBytes: conn.out_bytes,
                        lastTimestamp: currentTime
                    };
                }
        
                var history = view.connectionHistory[key];
                var instantInPps = 0, instantOutPps = 0, instantInBps = 0, instantOutBps = 0;
        
                if (lastConn && timeDiff > 0) {
                    var inPacketDiff = Math.max(0, conn.in_packets - history.lastInPackets);
                    var outPacketDiff = Math.max(0, conn.out_packets - history.lastOutPackets);
                    var inBytesDiff = Math.max(0, conn.in_bytes - history.lastInBytes);
                    var outBytesDiff = Math.max(0, conn.out_bytes - history.lastOutBytes);
                    
                    instantInPps = Math.round(inPacketDiff / timeDiff);
                    instantOutPps = Math.round(outPacketDiff / timeDiff);
                    instantInBps = Math.round(inBytesDiff / timeDiff);
                    instantOutBps = Math.round(outBytesDiff / timeDiff);
        
                    history.inPpsHistory.push(instantInPps);
                    history.outPpsHistory.push(instantOutPps);
                    history.inBpsHistory.push(instantInBps);
                    history.outBpsHistory.push(instantOutBps);
        
                    if (history.inPpsHistory.length > view.historyLength) {
                        history.inPpsHistory.shift();
                        history.outPpsHistory.shift();
                        history.inBpsHistory.shift();
                        history.outBpsHistory.shift();
                    }
                }
        
                history.lastInPackets = conn.in_packets;
                history.lastOutPackets = conn.out_packets;
                history.lastInBytes = conn.in_bytes;
                history.lastOutBytes = conn.out_bytes;
                history.lastTimestamp = currentTime;
        
                var avgInPps = Math.round(history.inPpsHistory.reduce((a, b) => a + b, 0) / history.inPpsHistory.length) || 0;
                var avgOutPps = Math.round(history.outPpsHistory.reduce((a, b) => a + b, 0) / history.outPpsHistory.length) || 0;
                var avgInBps = Math.round(history.inBpsHistory.reduce((a, b) => a + b, 0) / history.inBpsHistory.length) || 0;
                var avgOutBps = Math.round(history.outBpsHistory.reduce((a, b) => a + b, 0) / history.outBpsHistory.length) || 0;
                var maxInPps = Math.max(...history.inPpsHistory, 0);
                var maxOutPps = Math.max(...history.outPpsHistory, 0);
        
                conn.avgInPps = avgInPps;
                conn.avgOutPps = avgOutPps;
                conn.maxInPps = maxInPps;
                conn.maxOutPps = maxOutPps;
                conn.avgInBps = avgInBps;
                conn.avgOutBps = avgOutBps;
                view.lastData[key] = conn;
            });
        
            connections.sort(view.sortFunction.bind(view));
        
            connections.forEach(function(conn) {
                var srcFull = conn.src + ':' + (conn.sport || '-');
                var dstFull = conn.dst + ':' + (conn.dport || '-');
                var dscpString = dscpToString(conn.dscp);
                
                if (view.filter && !(
                    conn.protocol.toLowerCase().includes(view.filter) ||
                    srcFull.toLowerCase().includes(view.filter) ||
                    dstFull.toLowerCase().includes(view.filter) ||
                    dscpString.toLowerCase().includes(view.filter)
                )) {
                    return;
                }

                var srcFull = conn.src + (conn.sport !== "-" ? ':' + conn.sport : '');
                var dstFull = conn.dst + (conn.dport !== "-" ? ':' + conn.dport : '');                

                table.appendChild(E('tr', { 'class': 'tr' }, [
                    E('td', { 'class': 'td' }, conn.protocol.toUpperCase()),
                    E('td', { 'class': 'td' }, srcFull),
                    E('td', { 'class': 'td' }, dstFull),
                    E('td', { 'class': 'td' }, dscpString),
                    E('td', { 'class': 'td' }, 
                        E('div', {}, [
                            E('span', {}, _('In: ') + formatSize(conn.in_bytes)),
                            E('br'),
                            E('span', {}, _('Out: ') + formatSize(conn.out_bytes))
                        ])
                    ),
                    E('td', { 'class': 'td' }, 
                        E('div', {}, [
                            E('span', {}, _('In: ') + conn.in_packets),
                            E('br'),
                            E('span', {}, _('Out: ') + conn.out_packets)
                        ])
                    ),
                    E('td', { 'class': 'td' }, 
                        E('div', {}, [
                            E('span', {}, _('In: ') + conn.avgInPps),
                            E('br'),
                            E('span', {}, _('Out: ') + conn.avgOutPps)
                        ])
                    ),
                    E('td', { 'class': 'td' }, 
                        E('div', {}, [
                            E('span', {}, _('In: ') + conn.maxInPps),
                            E('br'),
                            E('span', {}, _('Out: ') + conn.maxOutPps)
                        ])
                    ),
                    E('td', { 'class': 'td' }, 
                        E('div', {}, [
                            E('span', {}, _('In: ') + convertToKbps(conn.avgInBps)),
                            E('br'),
                            E('span', {}, _('Out: ') + convertToKbps(conn.avgOutBps))
                        ])
                    )
                ]));
            });
            view.updateSortIndicators();            
        };

        view.updateTable(connections);
        this.updateSortIndicators();

        poll.add(function() {
            return callQoSmateConntrackDSCP().then(function(result) {
                if (result && result.connections) {
                    view.updateTable(Object.values(result.connections));
                } else {
                    console.error('Invalid data received:', result);
                }
            });
        }, view.pollInterval);

        var style = E('style', {}, `
            .sort-indicator {
                display: inline-block;
                width: 0;
                height: 0;
                margin-left: 5px;
                vertical-align: middle;
            }
        `);
        
        return E('div', { 'class': 'cbi-map' }, [
            style,
            E('h2', _('QoSmate Connections')),
            E('div', { 'style': 'margin-bottom: 10px;' }, [
                filterInput
            ]),
            E('div', { 'class': 'cbi-section' }, [
                E('div', { 'class': 'cbi-section-node' }, [
                    table
                ])
            ])
        ]);
    },

    sortTable: function(column, ev) {
        ev.preventDefault();
        if (this.sortColumn === column) {
            this.sortDescending = !this.sortDescending;
        } else {
            this.sortColumn = column;
            this.sortDescending = true;
        }
        var connections = Object.values(this.lastData);
        this.updateTable(connections);
        this.updateSortIndicators();
    },

    sortFunction: function(a, b) {
        var aValue, bValue;
        
        switch(this.sortColumn) {
            case 'bytes':
                aValue = (a.in_bytes || 0) + (a.out_bytes || 0);
                bValue = (b.in_bytes || 0) + (b.out_bytes || 0);
                break;
            case 'packets':
                aValue = (a.in_packets || 0) + (a.out_packets || 0);
                bValue = (b.in_packets || 0) + (b.out_packets || 0);
                break;
            case 'avgPps':
                aValue = (a.avgInPps || 0) + (a.avgOutPps || 0);
                bValue = (b.avgInPps || 0) + (b.avgOutPps || 0);
                break;
            case 'maxPps':
                aValue = Math.max(a.maxInPps || 0, a.maxOutPps || 0);
                bValue = Math.max(b.maxInPps || 0, b.maxOutPps || 0);
                break;
            case 'avgBps':
                aValue = (a.avgInBps || 0) + (a.avgOutBps || 0);
                bValue = (b.avgInBps || 0) + (b.avgOutBps || 0);
                break;
            default:
                aValue = a[this.sortColumn];
                bValue = b[this.sortColumn];
        }
        
        if (typeof aValue === 'string') aValue = aValue.toLowerCase();
        if (typeof bValue === 'string') bValue = bValue.toLowerCase();
    
        if (aValue < bValue) return this.sortDescending ? 1 : -1;
        if (aValue > bValue) return this.sortDescending ? -1 : 1;
        return 0;
    },

    createSortIndicator: function(column) {
        return E('span', { 'class': 'sort-indicator', 'data-column': column }, '');
    },

    updateSortIndicators: function() {
        var indicators = document.querySelectorAll('.sort-indicator');
        indicators.forEach(function(indicator) {
            if (indicator.dataset.column === this.sortColumn) {
                indicator.textContent = this.sortDescending ? ' ▼' : ' ▲';
            } else {
                indicator.textContent = '';
            }
        }.bind(this));
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
