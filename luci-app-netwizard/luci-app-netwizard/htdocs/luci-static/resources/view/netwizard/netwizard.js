'use strict';
'require view';
'require form';
'require network';
'require uci';
'require validation';
'require rpc';
'require fs';
'require dom';
'require poll';
'require tools.widgets as widgets';

return view.extend({
    load: function() {
        return Promise.all([
            network.getDevices(),
            uci.changes(),
            L.resolveDefault(uci.load('wireless'), null),
            uci.load('network'),
            uci.load('netwizard')
        ]);
    },

    render: function(data) {
        var devices = data[0] || [];
        var has_wifi = false;
        var m, o, s;

        try {
            var wirelessSections = uci.sections('wireless', 'wifi-device');
            if (wirelessSections && wirelessSections.length > 0) {
                has_wifi = true;
            } else {
                var wifiIfaces = uci.sections('wireless', 'wifi-iface');
                if (wifiIfaces && wifiIfaces.length > 0) {
                    has_wifi = true;
                }
            }
        } catch (e) {
            has_wifi = false;
        }

        var physicalIfaces = 0;
        var physicalInterfaces = [];
        
        for (var i = 0; i < devices.length; i++) {
            var iface = devices[i].getName();
            if (!iface.match(/_ifb$/) && !iface.match(/^ifb/) && 
                !iface.match(/^veth/) && !iface.match(/^tun/) &&
                !iface.match(/^tap/) && !iface.match(/^gre/) &&
                !iface.match(/^gretap/) && !iface.match(/^lo$/) &&
                !iface.match(/^br-/) &&
                (iface.match(/^(eth|en|usb)/) || iface.match(/^wlan|^wl/))) {
                
                physicalIfaces++;
                physicalInterfaces.push(iface);
            }
        }

        var lan_gateway = uci.get('netwizard', 'default', 'lan_gateway');
        var lan_ip = uci.get('netwizard', 'default', 'lan_ip');
        var lan_proto = uci.get('netwizard', 'default', 'lan_proto');
        var wan_face = uci.get('netwizard', 'default', 'wan_interface');
        var wanproto = uci.get('netwizard', 'default', 'wan_proto');
        
        if (physicalIfaces <= 1) {
            wanproto = 'siderouter';
            uci.set('netwizard', 'default', 'wan_proto', 'siderouter');
            uci.save();
        }

        if (!lan_ip) {
            lan_ip = uci.get('network', 'lan', 'ipaddr');
        }
        if (!lan_gateway && lan_ip) {
            var parts = lan_ip.split('.');
            if (parts.length === 4) {
                lan_gateway = parts[0] + '.' + parts[1] + '.' + parts[2] + '.';
            }
        }
        
        if (!wan_face) {
            wan_face = uci.get('network', 'wan', 'device') || uci.get('network', 'wan', 'ifname') || '';
        }
        
        if (!wanproto) {
            wanproto = uci.get('network', 'wan', 'proto') || 'siderouter';
        }
        
        // 存储配置数据供后续使用
        this.devices = devices;
        this.has_wifi = has_wifi;
        this.physicalIfaces = physicalIfaces;
        this.physicalInterfaces = physicalInterfaces;
        this.lan_gateway = lan_gateway;
        this.lan_ip = lan_ip;
        this.lan_proto = lan_proto;
        this.wan_face = wan_face;
        this.wanproto = wanproto;
        
        // 添加CSS样式
        this.addStyles();
        
        // 检查URL参数，如果有selectedMode则直接显示配置表单
        var params = new URLSearchParams(window.location.search);
        var selectedMode = params.get('selectedMode');
        
        if (selectedMode) {
            return this.renderConfigForm(selectedMode);
        } else {
            return this.renderModeSelection();
        }
    },

    addStyles: function() {
        if (document.getElementById('netwizard-mode-styles')) {
            return;
        }
        
        var style = E('style', { 'id': 'netwizard-mode-styles' }, `

            
            .mode-grid {
                display: flex;
                flex-wrap: wrap;
                gap: 20px;
                margin: 30px 0;
                justify-content: center;
            }
            
            .mode-card {
                border-radius: 8px;
                padding: 5rem 1rem;
                cursor: pointer;
                transition: all 0.3s;
                text-align: center;
                flex: 1;
                min-width: 200px;
                max-width: 200px;
                box-shadow: 0 0.1rem 0.3rem var(--input-boxcolor);
                display: flex;
                flex-direction: column;
                align-items: center;
                border: 2px solid transparent;
            }
            
            .mode-card:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            }
            
            /* PPPoE模式 - 红色主题 */
            .mode-card[data-mode="pppoe"] {
                background: linear-gradient(135deg, #ff6b6b 0%, #ff4757 100%);
                border-color: #ff4757;
                color: white;
            }
            
            .mode-card[data-mode="pppoe"]:hover {
                border-color: #ff3838;
                box-shadow: 0 4px 12px rgba(255, 71, 87, 0.3);
            }
            
            /* DHCP模式 - 绿色主题 */
            .mode-card[data-mode="dhcp"] {
                background: linear-gradient(135deg, #51cf66 0%, #40c057 100%);
                border-color: #40c057;
                color: white;
            }
            
            .mode-card[data-mode="dhcp"]:hover {
                border-color: #37b24d;
                box-shadow: 0 4px 12px rgba(64, 192, 87, 0.3);
            }
            
            /* SideRouter模式 - 蓝色主题 */
            .mode-card[data-mode="siderouter"] {
                background: linear-gradient(135deg, #339af0 0%, #228be6 100%);
                border-color: #228be6;
                color: white;
            }
            
            .mode-card[data-mode="siderouter"]:hover {
                border-color: #1c7ed6;
                box-shadow: 0 4px 12px rgba(34, 139, 230, 0.3);
            }
            
            .mode-icon-container {
                width: 64px;
                height: 64px;
                margin-bottom: 15px;
                display: flex;
                align-items: center;
                justify-content: center;
                background: rgba(255, 255, 255, 0.2);
                border-radius: 50%;
                padding: 10px;
            }
            
            .mode-icon-bg {
                width: 64px;
                height: 64px;
                margin-bottom: 15px;
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 50%;
                padding: 10px;
            }
            
            .mode-icon {
                width: 48px;
                height: 48px;
                object-fit: contain;
            }
            
            .mode-title {
                font-size: 16px;
                font-weight: 600;
                margin-top: 10px;
                text-align: center;
            }
            
            .mode-description {
                font-size: 13px;
                line-height: 1.4;
                margin-bottom: 15px;
                min-height: 60px;
                text-align: center;
                opacity: 0.9;
            }
            
            /* 快速导航按钮样式 */
            .quick-nav-buttons {
                display: flex;
                justify-content: center;
                gap: 10px;
                margin: 20px;
                flex-wrap: wrap;
            }
            
            .quick-nav-btn {
                padding: 8px 16px;
                color: white;
                border: none;
                border-radius: 4px;
                font-size: 14px;
		line-height: 1rem;
                cursor: pointer;
                transition: background 0.3s;
                text-decoration: none;
                display: inline-block;
            }
            
            
            .mode-info-header {
                border-radius: 8px;
                padding: 1rem;
                margin: 0 2% 2% 2%;
                display: flex;
                align-items: center;
                gap: 15px;
            }
            
            .mode-info-content {
                flex: 1;
            }
            
            .mode-info-header[data-mode="pppoe"] {
                background: #ff6b6b;
            }
            
            .mode-info-header[data-mode="dhcp"] {
                background: #51cf66;
            }
            
            .mode-info-header[data-mode="siderouter"] {
                background: #339af0;
            }
            
            @media (max-width: 768px) {
                .mode-grid {
                    flex-direction: column;
                    align-items: center;
                }
                
                .mode-card {
                    min-width: 100%;
                    max-width: 100%;
                }
                
                .quick-nav-buttons {
                    flex-direction: column;
                }
                
                .quick-nav-btn {
                    width: 100%;
                    text-align: center;
                }
                
                .mode-info-header {
                    flex-direction: column;
                    text-align: center;
                }
            }
        `);
        
        document.head.appendChild(style);
    },

    getModeIconBase64: function(mode) {
        switch(mode) {
            case 'pppoe':
                return 'data:image/svg+xml;base64,' + btoa('<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="40" height="40"><path fill="white" d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM19 18H6c-2.21 0-4-1.79-4-4s1.79-4 4-4h.71C7.37 7.69 9.48 6 12 6c2.76 0 5 2.24 5 5v2h2c1.66 0 3 1.34 3 3s-1.34 3-3 3z"/></svg>');
            case 'dhcp':
               return 'data:image/svg+xml;base64,' + btoa('<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="40" height="40"><path fill="white" d="M12 3C7.79 3 4.14 5.34 2.29 8.5c-.37.66.11 1.5.9 1.5h17.63c.79 0 1.27-.84.9-1.5C19.86 5.34 16.21 3 12 3zm0 5c-1.38 0-2.5 1.12-2.5 2.5S10.62 13 12 13s2.5-1.12 2.5-2.5S13.38 8 12 8zm0 6c-2.33 0-7 1.17-7 3.5V19h14v-1.5c0-2.33-4.67-3.5-7-3.5z"/></svg>');
            case 'siderouter':
               return 'data:image/svg+xml;base64,' + btoa('<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="40" height="40"><path fill="white" d="M6.99 11L3 15l3.99 4v-3H14v-2H6.99v-3zM21 9l-3.99-4v3H10v2h7.01v3L21 9z"/></svg>');
        }
    },

    getModeIcon: function(mode) {
        var svgUrl = this.getModeIconBase64(mode);
        return '<img src="' + svgUrl + '" alt="' + mode + ' icon" class="mode-icon"  >';
    },

    // 获取模式标题
    getModeTitle: function(mode) {
        switch(mode) {
            case 'pppoe': return _('PPPoE Dial-up');
            case 'dhcp': return _('DHCP Client');
            case 'siderouter': return _('Side Router');
            default: return _('Network Mode');
        }
    },

    // 获取模式描述
    getModeDescription: function(mode) {
        switch(mode) {
            case 'pppoe': return _('For ADSL or fiber broadband with username/password');
            case 'dhcp': return _('Connect to router and automatically obtain IP via DHCP');
            case 'siderouter': return _('Configure as side router in same network as main router');
            default: return _('Network connection mode');
        }
    },

    // 获取模式颜色
    getModeColor: function(mode) {
        switch(mode) {
            case 'pppoe': return '#ff6b6b';
            case 'dhcp': return '#51cf66';
            case 'siderouter': return '#339af0';
            default: return '#36c';
        }
    },

    renderModeSelection: function() {
        var container = E('div', { 'class': 'mode-selection-container' }, [
            E('h3', { 'style': 'margin-top: 4%; margin-bottom: 15px; text-align: center;' },
                _('Select Network Connection Mode')),
            E('p', { 'style': 'margin-bottom: %1; text-align: center;' },
                _('Choose the connection mode that matches your network environment:'))
        ]);
        
        var modeGrid = E('div', { 'class': 'mode-grid' });
        
        var modes = [
            { id: 'pppoe' },
            { id: 'dhcp' },
            { id: 'siderouter' }
        ];
        
        var self = this;
        modes.forEach(function(mode) {
            var iconDiv = E('div', { 
                'class': 'mode-icon-container'
            });
            
            iconDiv.innerHTML = self.getModeIcon(mode.id);
            
            var card = E('div', {
                'class': 'mode-card',
                'data-mode': mode.id
            }, [
                iconDiv,
                E('div', { 'class': 'mode-title' }, self.getModeTitle(mode.id)),
                // E('div', { 'class': 'mode-description' }, self.getModeDescription(mode.id))
            ]);
            
            card.addEventListener('click', function() {
                self.selectMode(mode.id);
            });
            
            modeGrid.appendChild(card);
        });
        
        container.appendChild(modeGrid);
        return container;
    },

    selectMode: function(mode) {
        uci.set('netwizard', 'default', 'wan_proto', mode);
        uci.save();
        
        var currentUrl = window.location.pathname;
        var newUrl = currentUrl + '?selectedMode=' + mode + '&tab=wansetup';
        window.location.href = newUrl;
    },

    renderConfigForm: function(selectedMode) {
        var wanproto = selectedMode || this.wanproto;
        
        // 创建form.Map
        var m = new form.Map('netwizard', _('Quick Network Setup Wizard'),
            _('Quick network setup wizard. If you need more settings, please enter network - interface to set.'));
        
        var s = m.section(form.NamedSection, 'default', 'netwizard');
        s.addremove = false;
        s.anonymous = true;

        // 添加标签页
        s.tab('modesetup', _('Network Mode'));
        s.tab('wansetup', _('WAN Settings'));
        if (this.has_wifi) {
            s.tab('wifisetup', _('Wireless Settings'), _('Set the router\'s wireless name and password. For more advanced settings, please go to the Network-Wireless page.'));
        }
        s.tab('othersetup', _('Other Settings'));

        // 模式选择标签页 - 显示当前选择的模式
        var modeTitle = this.getModeTitle(wanproto);
        var modeIcon = this.getModeIcon(wanproto);
        var modeDescription = this.getModeDescription(wanproto);
        var modeColor = this.getModeColor(wanproto);
        
        var o = s.taboption('modesetup', form.DummyValue, 'current_mode', _('Current Network Mode'));
        o.rawhtml = true;
        o.default = '<div style="display: flex;align-items: center;flex-direction: column;">' +
                    '<div class="mode-icon-bg" style="margin-bottom: 20px;background: ' + modeColor + ';">' + modeIcon + '</div>' +
                    '<h3 >' + modeTitle + '</h3>' +
                    '<p >' + modeDescription + '</p>' +
                    '<div class="quick-nav-buttons">' +
		     '<button onclick="switchToTab(\'wansetup\')" class="quick-nav-btn" style="background: ' + modeColor + ';">' +
                    '⚙️ ' + _('Go to WAN Settings') + '</button>' +
                    '<a href="' + window.location.pathname + '" class="quick-nav-btn cbi-button cbi-button-reset">' +
                    '↻ ' + _('Change Mode') + '</a>' +
                    '</div>' +
                    '</div>';

        var modeInfoHeader = s.taboption('wansetup', form.DummyValue, 'mode_info_header', '');
        modeInfoHeader.rawhtml = true;
        modeInfoHeader.default = '<div class="mode-info-header" data-mode="' + wanproto + '">' +
                                 '<div class="mode-icon-container cbi-value-title">' + modeIcon + '</div>' +
                                 '<div class="mode-info-content cbi-value-field">' +
                                 '<h4 style="margin: 0 0 5px 0; color: #fff;">' + modeTitle + '</h4>' +
                                 '<p style="margin: 0; font-size: 14px; color: #fff;">' + modeDescription + '</p>' +
                                 '<div style="margin: 10px;">' +
                    '<a href="' + window.location.pathname + '" class="quick-nav-btn cbi-button cbi-button-reset">' +
                    '↻ ' + _('Change Mode') + '</a>' +

                                 '</div>' +
                                 '</div>' +
                                 '</div>';

        o = s.taboption('modesetup', form.ListValue, 'wan_proto', _('Network protocol mode selection'), 
            _('Three different ways to access the Internet, please choose according to your own situation.'));
        o.default = wanproto;
        o.value('dhcp', _('DHCP client (Connect to the router)'));
        o.value('pppoe', _('PPPoE dialing (Main route dial-up)'));
        o.value('siderouter', _('SideRouter (Same network as the main router)'));
        o.rmempty = false;
	o.readonly = true;
    
        // LAN Settings for SideRouter mode
        o = s.taboption('wansetup', form.ListValue, 'lan_proto', _('LAN IP Address Mode'), 
            _('Choose how to get IP address for LAN interface'));
        o.default = 'static';
        o.value('static', _('Static IP address (Specify non conflicting IP addresses)'));
        o.value('dhcp', _('DHCP client (Main router assigns IP)'));
        o.depends('wan_proto', 'siderouter');
        o.rmempty = false;

        // WAN interface Settings for set mode
        o = s.taboption('wansetup', form.ListValue, 'dhcp_proto', _('WAN interface IP address mode'), 
            _('Choose how to get IP address for WAN interface'));
        o.default = 'dhcp';
        o.value('static', _('Static IP address (Specify non conflicting IP addresses)'));
        o.value('dhcp', _('DHCP client (Main router assigns IP)'));
        o.depends('wan_proto', 'dhcp');
        o.rmempty = false;
	
        o = s.taboption('wansetup', form.Value, 'lan_ipaddr', _('LAN IPv4 Address'), 
            _('You must specify the IP address of this machine, which is the IP address of the web access route'));
        o.default = this.lan_ip;
        o.datatype = 'ip4addr';
        o.rmempty = false;
        o.depends('wan_proto', 'pppoe');
        o.depends('wan_proto', 'dhcp');
        o.depends({'wan_proto': 'siderouter', 'lan_proto': 'static'});

        o = s.taboption('wansetup', form.Value, 'lan_netmask', _('LAN IPv4 Netmask'));
        o.datatype = 'ip4addr';
        o.value('255.255.255.0');
        o.value('255.255.0.0');
        o.value('255.0.0.0');
        o.default = '255.255.255.0';
        o.depends({'wan_proto': 'siderouter', 'lan_proto': 'static'});
        o.depends('wan_proto', 'pppoe');
        o.depends('wan_proto', 'dhcp');
        o.rmempty = false;

        o = s.taboption('wansetup', form.Value, 'lan_gateway', _('LAN IPv4 Gateway'), 
            _('Please enter the main routing IP address. The bypass gateway is not the same as the login IP of this bypass WEB and is in the same network segment'));
        o.default = this.lan_gateway;
        o.depends({'wan_proto': 'siderouter', 'lan_proto': 'static'});
        o.datatype = 'ip4addr';
        o.rmempty = false;

        o = s.taboption('wansetup', form.DynamicList, 'lan_dns', _('Use Custom SideRouter DNS'));
        o.value('223.5.5.5', _('Ali DNS: 223.5.5.5'));
        o.value('180.76.76.76', _('Baidu DNS: 180.76.76.76'));
        o.value('114.114.114.114', _('114 DNS: 114.114.114.114'));
        o.value('8.8.8.8', _('Google DNS: 8.8.8.8'));
        o.value('1.1.1.1', _('Cloudflare DNS: 1.1.1.1'));
        o.depends({'wan_proto': 'siderouter'});
        o.datatype = 'ip4addr';
        o.default = '223.5.5.5';
        o.rmempty = false;

        // WAN Interface for other modes
        o = s.taboption('wansetup', widgets.DeviceSelect, 'wan_interface', 
            _('Device'), 
            _('Allocate the physical interface of WAN port'));
        o.depends('wan_proto', 'pppoe');
        o.depends('wan_proto', 'dhcp');
        o.default = this.wan_face;
        o.ucioption = 'wan_interface';
        o.nobridges = false;
        o.rmempty = false;
        
        o = s.taboption('wansetup', form.Value, 'wan_pppoe_user', _('PAP/CHAP Username'));
        o.depends('wan_proto', 'pppoe');
        o.rmempty = false;

        o = s.taboption('wansetup', form.Value, 'wan_pppoe_pass', _('PAP/CHAP Password'));
        o.depends('wan_proto', 'pppoe');
        o.password = true;
        o.rmempty = false;

        o = s.taboption('wansetup', form.Value, 'wan_ipaddr', _('WAN IPv4 Address'));
        o.depends({'wan_proto': 'dhcp', 'dhcp_proto': 'static'});
        o.datatype = 'ip4addr';
        o.rmempty = false;

        o = s.taboption('wansetup', form.Value, 'wan_netmask', _('WAN IPv4 Netmask'));
        o.depends({'wan_proto': 'dhcp', 'dhcp_proto': 'static'});
        o.datatype = 'ip4addr';
        o.value('255.255.255.0');
        o.value('255.255.0.0');
        o.value('255.0.0.0');
        o.default = '255.255.255.0';
        o.rmempty = false;

        o = s.taboption('wansetup', form.Value, 'wan_gateway', _('WAN IPv4 Gateway'));
        o.depends({'wan_proto': 'dhcp', 'dhcp_proto': 'static'});
        o.datatype = 'ip4addr';
        o.rmempty = false;

        o = s.taboption('wansetup', form.DynamicList, 'wan_dns', _('Use Custom WAN DNS'));
        o.value('', _('none'));
        o.value('223.5.5.5', _('Ali DNS: 223.5.5.5'));
        o.value('180.76.76.76', _('Baidu DNS: 180.76.76.76'));
        o.value('114.114.114.114', _('114 DNS: 114.114.114.114'));
        o.value('8.8.8.8', _('Google DNS: 8.8.8.8'));
        o.value('1.1.1.1', _('Cloudflare DNS: 1.1.1.1'));
        o.depends({'wan_proto': 'dhcp'});
        o.depends('wan_proto', 'pppoe');
        o.datatype = 'ip4addr';

        o = s.taboption('wansetup', form.Flag, 'ipv6', _('Enable IPv6'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('wansetup', form.Flag, 'lan_dhcp', _('Disable DHCP Server'), 
            _('Selecting means that the DHCP server is not enabled. In a network, only one DHCP server is needed to allocate and manage client IPs. If it is a secondary route, it is recommended to turn off the primary routing DHCP server.'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('wansetup', form.Flag, 'dnsset', _('Enable DNS Notifications (IPv4/IPv6)'),
            _('Forcefully specify the DNS server for this router'));
        o.depends('lan_dhcp', '0');
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('wansetup', form.ListValue, 'dns_tables', _('DNS'));
        o.value('1', _('Use local IP for DNS (default)'));
        o.value('223.5.5.5', _('Ali DNS: 223.5.5.5'));
        o.value('180.76.76.76', _('Baidu DNS: 180.76.76.76'));
        o.value('114.114.114.114', _('114 DNS: 114.114.114.114'));
        o.value('8.8.8.8', _('Google DNS: 8.8.8.8'));
        o.value('1.1.1.1', _('Cloudflare DNS: 1.1.1.1'));
        o.depends('dnsset', '1');
        o.rmempty = false;

        o = s.taboption('wansetup', form.Flag, 'forwarding', _('Forcefully Forwarding'),
            _('Forcefully add LAN to WAN forwarding'));
        o.default = '1';
        o.depends('wan_proto', 'pppoe');
        o.depends('wan_proto', 'dhcp');
        o.rmempty = false;

        o = s.taboption('wansetup', form.Flag, 'https', _('Redirect to HTTPS'),
            _('Enable automatic redirection of HTTP requests to HTTPS port.'));
        o.default = '0';
        o.rmempty = false;
        
        if (this.has_wifi) {
            var wifi_ssid = s.taboption('wifisetup', form.Value, 'wifi_ssid', _('<abbr title="Extended Service Set Identifier">ESSID</abbr>'));
            wifi_ssid.datatype = 'maxlength(32)';

            var wifi_key = s.taboption('wifisetup', form.Value, 'wifi_key', _('Key'));
            wifi_key.datatype = 'wpakey';
            wifi_key.password = true;
        }

        // Other Settings Tab
        o = s.taboption('othersetup', form.Flag, 'synflood', _('Enable SYN-flood Defense'),
            _('Enable Firewall SYN-flood defense [Suggest opening]'));
        o.default = '1';
        o.rmempty = false;

        // 保存原始的save方法
        var originalSave = m.save;
        var currentLanIP = this.lan_ip;
        
        // 获取新IP地址的函数
        function getNewLanIP() {
            var selectors = [
                'input[name="cbid.netwizard.default.lan_ipaddr"]',
                'input[name="widget.cbid.netwizard.default.lan_ipaddr"]',
                'input[data-option="lan_ipaddr"]',
                'input[placeholder*="IP"]',
                '.cbi-input-text[type="text"]'
            ];
            
            for (var i = 0; i < selectors.length; i++) {
                var inputs = document.querySelectorAll(selectors[i]);
                for (var j = 0; j < inputs.length; j++) {
                    var input = inputs[j];
                    if (input && input.value) {
                        var ipMatch = input.value.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
                        if (ipMatch) {
                            var valid = true;
                            for (var k = 1; k <= 4; k++) {
                                var part = parseInt(ipMatch[k]);
                                if (part < 0 || part > 255) {
                                    valid = false;
                                    break;
                                }
                            }
                            if (valid) {
                                return input.value;
                            }
                        }
                    }
                }
            }
            
            return null;
        }

        function showRedirectMessage(newIP) {
            var overlay = document.createElement('div');
            overlay.id = 'netwizard-redirect-overlay';
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.85);
                z-index: 9999;
                display: flex;
                justify-content: center;
                align-items: center;
                font-family: Arial, sans-serif;
            `;
            
            var messageBox = document.createElement('div');
            messageBox.style.cssText = `
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 1rem;
                border-radius: 15px;
                text-align: center;
                max-width: 600px;
                box-shadow: 0 20px 40px rgba(0,0,0,0.3);
                color: white;
            `;
            
            var icon = document.createElement('div');
            icon.innerHTML = '✓';
            icon.style.cssText = `
                font-size: 60px;
                color: #4CAF50;
                background: white;
                width: 100px;
                height: 100px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 20px;
                font-weight: bold;
                box-shadow: 0 10px 20px rgba(0,0,0,0.2);
            `;
            
            var title = document.createElement('h2');
            title.textContent = _('Configuration Applied Successfully!');
            title.style.cssText = `
                margin: 0 0 20px 0;
                color: white;
            `;
            
            var message = document.createElement('div');
            message.innerHTML = _('The network configuration has been saved and applied.<br><br>') +
                               '<div style="background: rgba(255,255,255,0.2); border-radius: 10px; ">' +
                               _('New LAN IP Address: ') + 
                               '<strong style="color: #FFD700; font-size: 22px;">' + newIP + '</strong></div><br>' +
                               _('The page will automatically redirect in ') + 
                               '<span id="netwizard-countdown" style="color: #FFD700; font-size: 28px; font-weight: bold;">10</span>' + 
                               _(' seconds...');
            message.style.cssText = `
                color: rgba(255,255,255,0.9);
                line-height: 1.8;
                margin: 20px 0;
                font-size: 16px;
            `;
            
            var buttonContainer = document.createElement('div');
            buttonContainer.style.cssText = `
                display: flex;
                justify-content: center;
                gap: 15px;
                margin-top: 25px;
                flex-wrap: wrap;
            `;
            
            var redirectButton = document.createElement('button');
            redirectButton.textContent = _('Redirect Now');
            redirectButton.style.cssText = `
                background: #4CAF50;
                color: white;
                border: none;
                padding: 12px 30px;
                border-radius: 50px;
                font-size: 16px;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s ease;
                box-shadow: 0 5px 15px rgba(76, 175, 80, 0.4);
            `;
            redirectButton.onmouseover = function() {
                this.style.transform = 'translateY(-2px)';
                this.style.boxShadow = '0 8px 20px rgba(76, 175, 80, 0.6)';
            };
            redirectButton.onmouseout = function() {
                this.style.transform = 'translateY(0)';
                this.style.boxShadow = '0 5px 15px rgba(76, 175, 80, 0.4)';
            };
            redirectButton.onclick = function() {
                redirectToNewIP(newIP);
            };
            
            var cancelButton = document.createElement('button');
            cancelButton.textContent = _('Stay Here');
            cancelButton.style.cssText = `
                background: rgba(255,255,255,0.2);
                color: white;
                border: 2px solid white;
                padding: 12px 30px;
                border-radius: 50px;
                font-size: 16px;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s ease;
            `;
            cancelButton.onmouseover = function() {
                this.style.background = 'rgba(255,255,255,0.3)';
                this.style.transform = 'translateY(-2px)';
            };
            cancelButton.onmouseout = function() {
                this.style.background = 'rgba(255,255,255,0.2)';
                this.style.transform = 'translateY(0)';
            };
            cancelButton.onclick = function() {
                hideRedirectMessage();
            };
            
            messageBox.appendChild(icon);
            messageBox.appendChild(title);
            messageBox.appendChild(message);
            buttonContainer.appendChild(redirectButton);
            messageBox.appendChild(buttonContainer);
            overlay.appendChild(messageBox);
            
            document.body.appendChild(overlay);
            
            var countdown = 10;
            var countdownElement = document.getElementById('netwizard-countdown');
            
            var countdownInterval = setInterval(function() {
                countdown--;
                if (countdownElement) {
                    countdownElement.textContent = countdown;
                    
                    if (countdown <= 3) {
                        countdownElement.style.color = (countdown % 2 === 0) ? '#FF6B6B' : '#FFD700';
                    }
                }
                
                if (countdown <= 0) {
                    clearInterval(countdownInterval);
                    redirectToNewIP(newIP);
                }
            }, 1000);
            
            overlay._countdownInterval = countdownInterval;
        }
        
        function hideRedirectMessage() {
            var overlay = document.getElementById('netwizard-redirect-overlay');
            if (overlay) {
                if (overlay._countdownInterval) {
                    clearInterval(overlay._countdownInterval);
                }
                document.body.removeChild(overlay);
            }
        }
        
        function redirectToNewIP(newIP) {
            hideRedirectMessage();
            
            var currentProtocol = window.location.protocol;
            var currentPort = window.location.port ? ':' + window.location.port : '';
            var newURL = currentProtocol + '//' + newIP + currentPort + '/';
            
            var jumpMsg = document.createElement('div');
            jumpMsg.id = 'netwizard-jump-msg';
            jumpMsg.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                background: #4CAF50;
                color: white;
                padding: 15px 25px;
                border-radius: 10px;
                z-index: 10000;
                font-weight: bold;
                box-shadow: 0 5px 15px rgba(0,0,0,0.3);
                animation: slideIn 0.5s ease;
            `;
            
            var style = document.createElement('style');
            style.textContent = `
                @keyframes slideIn {
                    from { transform: translateX(100%); opacity: 0; }
                    to { transform: translateX(0); opacity: 1; }
                }
            `;
            document.head.appendChild(style);
            
            jumpMsg.textContent = _('Redirecting to') + newIP + '...';
            document.body.appendChild(jumpMsg);
            
            setTimeout(function() {
                try {
                    window.location.href = newURL;
                } catch (e) {
                    alert(_('Failed to redirect to ') + newIP + 
                          _('\nPlease manually access:\n') + newURL);
                    
                    var jumpMsg = document.getElementById('netwizard-jump-msg');
                    if (jumpMsg) {
                        document.body.removeChild(jumpMsg);
                    }
                }
            }, 1000);
        }

        function executeNetwizardScript(newIP) {
            return new Promise(function(resolve, reject) {
                var applyingMsg = document.createElement('div');
                applyingMsg.id = 'netwizard-applying-msg';
                applyingMsg.style.cssText = `
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    background: rgba(0,0,0,0.9);
                    color: white;
                    padding: 20px 40px;
                    border-radius: 10px;
                    z-index: 9998;
                    font-size: 16px;
                `;
                applyingMsg.textContent = _('Applying network configuration...');
                document.body.appendChild(applyingMsg);
                
                var callRPC = rpc.declare({
                    object: 'file',
                    method: 'exec',
                    params: ['command', 'params', 'env'],
                    expect: { '': {} }
                });
                
                setTimeout(function() {
                    fs.stat('/etc/init.d/netwizard').then(function(stats) {
                        return callRPC('/etc/init.d/netwizard', ['start'], {});
                    }).then(function(response) {
                        if (applyingMsg && applyingMsg.parentNode) {
                            document.body.removeChild(applyingMsg);
                        }
                        showRedirectMessage(newIP);
                        setTimeout(function() {
                            redirectToNewIP(newIP);
                        }, 10000);
                        
                        resolve(response);
                    }).catch(function(err) {
                        if (applyingMsg && applyingMsg.parentNode) {
                            document.body.removeChild(applyingMsg);
                        }

                        showRedirectMessage(newIP);
                        
                        setTimeout(function() {
                            redirectToNewIP(newIP);
                        }, 10000);
                        
                        resolve({}); 
                    });
                }, 1000);
            });
        }

        // 重写save方法
        m.save = function() {
            var newLanIP = getNewLanIP();
            var ipChanged = newLanIP && currentLanIP !== newLanIP;

            var savingMsg = document.createElement('div');
            savingMsg.id = 'netwizard-saving-msg';
            savingMsg.style.cssText = `
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                background: rgba(0,0,0,0.9);
                color: white;
                padding: 20px 40px;
                border-radius: 10px;
                z-index: 9998;
                font-size: 16px;
            `;
            savingMsg.textContent = _('Saving configuration...');
            document.body.appendChild(savingMsg);
            
            return originalSave.call(m).then(function(result) {
                var msg = document.getElementById('netwizard-saving-msg');
                if (msg && msg.parentNode) {
                    document.body.removeChild(msg);
                }
                
                if (!ipChanged || !newLanIP) {
                    var successMsg = document.createElement('div');
                    successMsg.id = 'netwizard-success-msg';
                    successMsg.style.cssText = `
                        position: fixed;
                        top: 20px;
                        right: 20px;
                        background: #4CAF50;
                        color: white;
                        padding: 15px 25px;
                        border-radius: 10px;
                        z-index: 9999;
                        font-weight: bold;
                        animation: slideIn 0.5s ease;
                    `;
                    successMsg.textContent = _('Configuration saved successfully!');
                    document.body.appendChild(successMsg);
                    
                    setTimeout(function() {
                        var msg = document.getElementById('netwizard-success-msg');
                        if (msg && msg.parentNode) {
                            document.body.removeChild(msg);
                        }
                    }, 3000);
                    
                    return result;
                }

                return executeNetwizardScript(newLanIP).then(function() {
                    return result;
                }).catch(function(err) {
                    showRedirectMessage(newLanIP);
                    setTimeout(function() {
                        redirectToNewIP(newLanIP);
                    }, 10000);
                    
                    return result;
                });
            }).catch(function(err) {
                var msg = document.getElementById('netwizard-saving-msg');
                if (msg && msg.parentNode) {
                    document.body.removeChild(msg);
                }
                
                var errorMsg = document.createElement('div');
                errorMsg.id = 'netwizard-error-msg';
                errorMsg.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    background: #f44336;
                    color: white;
                    padding: 15px 25px;
                    border-radius: 10px;
                    z-index: 9999;
                    font-weight: bold;
                    animation: slideIn 0.5s ease;
                `;
                errorMsg.textContent = _('Failed to save configuration');
                document.body.appendChild(errorMsg);
                
                setTimeout(function() {
                    var msg = document.getElementById('netwizard-error-msg');
                    if (msg && msg.parentNode) {
                        document.body.removeChild(msg);
                    }
                }, 5000);
                
                throw err;
            });
        };

        var script = document.createElement('script');
        script.textContent = `
            function switchToTab(tabName) {
                var tabs = document.querySelectorAll('.cbi-tabmenu a');
                for (var i = 0; i < tabs.length; i++) {
                    var tab = tabs[i];
                    var tabText = tab.textContent || tab.innerText;
                    console.log('Checking tab:', tabText, 'looking for:', tabName);
                    if ((tabName === 'wansetup' && (tabText.trim() === 'WAN Settings' || tabText.includes('WAN') || tabText.includes('网络设置'))) ||
                        (tabName === 'modesetup' && (tabText.trim() === 'Network Mode' || tabText.includes('Mode') || tabText.includes('网络模式'))) ||
                        (tabName === 'wifisetup' && (tabText.trim() === 'Wireless Settings' || tabText.includes('Wireless') || tabText.includes('无线设置'))) ||
                        (tabName === 'othersetup' && (tabText.trim() === 'Other Settings' || tabText.includes('Other') || tabText.includes('其他设置')))) {
                        tab.click();
                        var tabItems = document.querySelectorAll('.cbi-tabmenu li');
                        tabItems.forEach(function(item) {
                            item.classList.remove('cbi-tab-active');
                        });
                        tab.parentNode.classList.add('cbi-tab-active');
                        break;
                    }
                }
            }
            
            if (window.location.search.includes('selectedMode')) {

                setTimeout(function() {
                    switchToTab('wansetup');
                }, 200);
                
                document.addEventListener('DOMContentLoaded', function() {
                    setTimeout(function() {
                        switchToTab('wansetup');
                    }, 100);
                });
            }
        `;
        
        document.head.appendChild(script);
        
        return m.render();
    }
});