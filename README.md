# [大灰狼的专用软件包]

#
#### [master]分支的为[[lede_source](https://github.com/coolsnowwolf/lede)]源码专用
#### [22.03]分支的为[[lienol_source](https://github.com/Lienol/openwrt)]源码专用
#### [openwrt-21.02]分支的为[[Mortal_source](https://github.com/immortalwrt/immortalwrt)]源码专用
#### 为什么要这样分开呢？因为每个源码作者习惯都不一样，有些源码带了某插件，有些源码又没带，我是尽量的做到源码自带的就用源码自带的，源码没带的就加入，这样就不会重覆了，减少编译错误的概率。
#

##### 添加以下插件
###### [luci-app-autotimeset](#/README.md) &emsp;&emsp; # 定时设置插件(定时重启、定时关机、定时重启网络)
###### [luci-app-adblock-plus](#/README.md) &emsp;&emsp; # 拦截广告
###### [luci-app-netspeedtest](#/README.md) &emsp;&emsp; # 网络测速
###### [luci-app-homeredirect](#/README.md) &emsp;&emsp; # 端口转发
###### [luci-app-quickstart](#/README.md) &emsp;&emsp; # iStoreOS-web
###### [luci-app-adguardhome](#/README.md) &emsp;&emsp; # adguardhome
###### [luci-app-lucky](#/README.md) &emsp;&emsp; # #替代socat,主要用于公网IPv6 tcp/udp转 内网ipv4
###### [luci-app-advanced](#/README.md) &emsp;&emsp; # 高级设置（内置luci-app-fileassistant文件助手）
###### LuCI ---> Applications ---> luci-app-accesscontrol&emsp;&emsp; #访问时间控制
###### LuCI ---> Applications ---> luci-app-adbyby-plus&emsp;&emsp; #广告屏蔽大师Plus +
###### LuCI ---> Applications ---> luci-app-arpbind&emsp;&emsp; #IP/MAC绑定
###### LuCI ---> Applications ---> luci-app-autoreboot &emsp;&emsp; #支持计划重启
###### LuCI ---> Applications ---> luci-app-ddns &emsp;&emsp;  #动态域名 DNS（集成阿里DDNS客户端）
###### LuCI ---> Applications ---> luci-app-filetransfer &emsp;&emsp;  #文件传输（可web安装ipk包）
###### LuCI ---> Applications ---> luci-app-firewall &emsp;&emsp;  #添加防火墙
###### LuCI ---> Applications ---> luci-app-flowoffload &emsp;&emsp;  #Turbo ACC网络加速（集成FLOW,BBR,NAT,DNS...
###### LuCI ---> Applications ---> luci-app-frpc &emsp;&emsp;  #内网穿透 Frp
###### LuCI ---> Applications ---> luci-app-guest-wifi &emsp;&emsp;  #WiFi访客网络
###### LuCI ---> Applications ---> luci-app-mwan3 &emsp;&emsp;  #MWAN3负载均衡
###### LuCI ---> Applications ---> luci-app-mwan3helper &emsp;&emsp;  #MWAN3分流助手
###### LuCI ---> Applications ---> luci-app-nlbwmon &emsp;&emsp;  #网络带宽监视器
###### LuCI ---> Applications ---> luci-app-ramfree &emsp;&emsp;  #释放内存
###### LuCI ---> Applications ---> luci-app-samba &emsp;&emsp;  #网络共享（Samba）
###### LuCI ---> Applications ---> luci-app-sqm&emsp;&emsp;  #流量智能队列管理（QOS）
###### LuCI ---> Applications ---> luci-app-syncdial&emsp;&emsp;  #多拨虚拟网卡（原macvlan）
###### LuCI ---> Applications ---> luci-app-unblockmusic &emsp;&emsp;  #解锁网易云灰色歌曲
###### LuCI ---> Applications ---> luci-app-upnp &emsp;&emsp;  #通用即插即用UPnP（端口自动转发）
###### LuCI ---> Applications ---> luci-app-vlmcsd &emsp;&emsp;  #KMS服务器设置
###### LuCI ---> Applications ---> luci-app-vsftpd &emsp;&emsp;  #FTP服务器
###### LuCI ---> Applications ---> luci-app-wifischedule &emsp;&emsp;  #WiFi 计划
###### LuCI ---> Applications ---> luci-app-wol &emsp;&emsp;  #WOL网络唤醒
###### LuCI ---> Applications ---> luci-app-wrtbwmon &emsp;&emsp;  #实时流量监测
###### LuCI ---> Applications ---> luci-app-xlnetacc &emsp;&emsp;  #迅雷快鸟
###### LuCI ---> Applications ---> luci-app-zerotier&emsp;&emsp;  #ZeroTier内网穿透
###### Extra packages ---> ipv6helper #支持 ipv6
```
Extra packages ---> ipv6helper （选定这个后下面几项自动选择了）
Network ---> odhcp6c
Network ---> odhcpd-ipv6only
LuCI ---> Protocols ---> luci-proto-ipv6
```
###### LuCI ---> Protocols ---> luci-proto-ppp
###### LuCI ---> Applications ---> luci-app-accesscontrol #访问时间控制
###### LuCI ---> Applications ---> luci-app-acme #ACME 自动化证书管理环境
###### LuCI ---> Applications ---> luci-app-adblock #ADB广告过滤
###### LuCI ---> Applications ---> luci-app-adbyby-plus #广告屏蔽大师Plus +
###### LuCI ---> Applications ---> luci-app-adbyby #广告过滤大师（已弃）
###### LuCI ---> Applications ---> luci-app-adkill #广告过滤（已弃）
###### LuCI ---> Applications ---> luci-app-advanced-reboot #Linksys高级重启
###### LuCI ---> Applications ---> luci-app-ahcp #支持AHCPd
###### LuCI ---> Applications ---> luci-app-aliddns #阿里DDNS客户端（已弃，集成至ddns）
###### LuCI ---> Applications ---> luci-app-amule #aMule下载工具
###### LuCI ---> Applications ---> luci-app-aria2 # Aria2下载工具
###### LuCI ---> Applications ---> luci-app-arpbind #IP/MAC绑定
###### LuCI ---> Applications ---> luci-app-asterisk #支持Asterisk电话服务器
###### LuCI ---> Applications ---> luci-app-attendedsysupgrade #固件更新升级相关
###### LuCI ---> Applications ---> luci-app-autoreboot #支持计划重启
###### LuCI ---> Applications ---> luci-app-baidupcs-web #百度网盘管理 *
###### LuCI ---> Applications ---> luci-app-bcp38 #BCP38网络入口过滤（不确定）
###### LuCI ---> Applications ---> luci-app-bird1-ipv4 #对Bird1-ipv4的支持
###### LuCI ---> Applications ---> luci-app-bird1-ipv6 #对Bird1-ipv6的支持
###### LuCI ---> Applications ---> luci-app-bird4 #Bird 4（未知）（已弃）
###### LuCI ---> Applications ---> luci-app-bird6 #Bird 6（未知）（已弃）
###### LuCI ---> Applications ---> luci-app-bmx6 #BMX6路由协议
###### LuCI ---> Applications ---> luci-app-bmx7 #BMX7路由协议
###### LuCI ---> Applications ---> luci-app-caldav #联系人（已弃）
###### LuCI ---> Applications ---> luci-app-cifsd #CIFS/SMB网络共享
###### LuCI ---> Applications ---> luci-app-cifs-mount   #CIFS/SMB挂载设置
###### LuCI ---> Applications ---> luci-app-cjdns #加密IPV6网络相关
###### LuCI ---> Applications ---> luci-app-clamav #ClamAV杀毒软件
###### LuCI ---> Applications ---> luci-app-commands #Shell命令模块
###### LuCI ---> Applications ---> luci-app-cshark #CloudShark捕获工具
###### LuCI ---> Applications ---> luci-app-ddns #动态域名 DNS（集成阿里DDNS客户端）
###### LuCI ---> Applications ---> luci-app-diag-core #core诊断工具
###### LuCI ---> Applications ---> luci-app-dnscrypt-proxy #DNSCrypt解决DNS污染
###### LuCI ---> Applications ---> luci-app-dnsforwarder    #DNSForwarder防DNS污染
###### LuCI ---> Applications ---> luci-app-dnspod    #DNSPod动态域名解析
###### LuCI ---> Applications ---> luci-app-dockerman    #Docker容器 *
###### LuCI ---> Applications ---> luci-app-dump1090    #民航无线频率（不确定）
###### LuCI ---> Applications ---> luci-app-dynapoint    #DynaPoint（未知）
###### LuCI ---> Applications ---> luci-app-e2guardian    #Web内容过滤器
###### LuCI ---> Applications ---> luci-app-familycloud    #家庭云盘
###### LuCI ---> Applications ---> luci-app-filetransfer    #文件传输（可web安装ipk包）
###### LuCI ---> Applications ---> luci-app-firewall    #添加防火墙
###### LuCI ---> Applications ---> luci-app-flowoffload    #Turbo ACC网络加速（集成FLOW,BBR,NAT,DNS...
###### LuCI ---> Applications ---> luci-app-freifunk-diagnostics    #freifunk组件 诊断（未知）
###### LuCI ---> Applications ---> luci-app-freifunk-policyrouting    #freifunk组件 策略路由（未知）
###### LuCI ---> Applications ---> luci-app-freifunk-widgets #freifunk组件 索引（未知）
###### LuCI ---> Applications ---> luci-app-frpc    #内网穿透 Frp
###### LuCI ---> Applications ---> luci-app-fwknopd   #Firewall Knock Operator服务器
###### LuCI ---> Applications ---> luci-app-guest-wifi   #WiFi访客网络
###### LuCI ---> Applications ---> luci-app-haproxy-tcp   #HAProxy负载均衡-TCP
###### LuCI ---> Applications ---> luci-app-hd-idle   #硬盘休眠
###### LuCI ---> Applications ---> luci-app-hnet   #Homenet Status家庭网络控制协议
###### LuCI ---> Applications ---> luci-app-ipsec-virtuald   #virtual服务器 IPSec
###### LuCI ---> Applications ---> luci-app-kodexplorer #KOD可道云私人网盘
###### LuCI ---> Applications ---> luci-app-kooldns #virtual**服务器 ddns替代方案（已弃）
###### LuCI ---> Applications ---> luci-app-koolproxy #KP去广告（已弃）
###### LuCI ---> Applications ---> luci-app-lxc #LXC容器管理
###### LuCI ---> Applications ---> luci-app-meshwizard #网络设置向导
###### LuCI ---> Applications ---> luci-app-minidlna #完全兼容DLNA / UPnP-AV客户端的服务器软件
###### LuCI ---> Applications ---> luci-app-mjpg-streamer #兼容Linux-UVC的摄像头程序
###### LuCI ---> Applications ---> luci-app-mtwifi #MTWiFi驱动的支持 *
###### LuCI ---> Applications ---> luci-app-mmc-over-gpio #添加SD卡操作界面（已弃）
###### LuCI ---> Applications ---> luci-app-multiwan #多拨虚拟网卡（已弃，移至syncdial）
###### LuCI ---> Applications ---> luci-app-mwan #MWAN负载均衡（已弃）
###### LuCI ---> Applications ---> luci-app-mwan3 #MWAN3负载均衡
###### LuCI ---> Applications ---> luci-app-mwan3helper #MWAN3分流助手
###### LuCI ---> Applications ---> luci-app-n2n_v2 #N2N内网穿透 N2N v2 virtual**服务
###### LuCI ---> Applications ---> luci-app-netdata #Netdata实时监控（图表） *
###### LuCI ---> Applications ---> luci-app-nft-qos #QOS流控 Nftables版
###### LuCI ---> Applications ---> luci-app-ngrokc #Ngrok 内网穿透（已弃）
###### LuCI ---> Applications ---> luci-app-nlbwmon #网络带宽监视器
###### LuCI ---> Applications ---> luci-app-noddos #NodDOS Clients 阻止DDoS攻击
###### LuCI ---> Applications ---> luci-app-nps #内网穿透nps *
###### LuCI ---> Applications ---> luci-app-ntpc #NTP时间同步服务器
###### LuCI ---> Applications ---> luci-app-olsr #OLSR配置和状态模块
###### LuCI ---> Applications ---> luci-app-olsr-services #OLSR服务器
###### LuCI ---> Applications ---> luci-app-olsr-viz #OLSR可视化
###### LuCI ---> Applications ---> luci-app-oscam #OSCAM服务器（已弃）
###### LuCI ---> Applications ---> luci-app-p910nd #打印服务器模块
###### LuCI ---> Applications ---> luci-app-pagekitec #Pagekite内网穿透客户端
###### LuCI ---> Applications ---> luci-app-polipo #Polipo代理(是一个小型且快速的网页缓存代理)
###### LuCI ---> Applications ---> luci-app-pppoe-relay #PPPoE NAT穿透 点对点协议（PPP）
###### LuCI ---> Applications ---> luci-app-privoxy #Privoxy网络代理(带过滤无缓存)
###### LuCI ---> Applications ---> luci-app-qbittorrent #BT下载工具（qBittorrent）
###### LuCI ---> Applications ---> luci-app-qos #流量服务质量(QoS)流控
###### LuCI ---> Applications ---> luci-app-radicale #CalDAV/CardDAV同步工具
###### LuCI ---> Applications ---> luci-app-ramfree #释放内存
###### LuCI ---> Applications ---> luci-app-rp-pppoe-server #Roaring Penguin PPPoE Server 服务器
###### LuCI ---> Applications ---> luci-app-samba #网络共享（Samba）
###### LuCI ---> Applications ---> luci-app-samba4 #网络共享（Samba4）
###### LuCI ---> Applications ---> luci-app-sfe #Turbo ACC网络加速（flowoffload二选一）
###### LuCI ---> Applications ---> luci-app-shairplay #支持AirPlay功能
###### LuCI ---> Applications ---> luci-app-siitwizard #SIIT配置向导 SIIT-Wizzard
###### LuCI ---> Applications ---> luci-app-simple-adblock #简单的广告拦截
###### LuCI ---> Applications ---> luci-app-smartdns #SmartDNS本地服务器 *
###### LuCI ---> Applications ---> luci-app-splash #Client-Splash是无线MESH网络的一个热点认证系统
###### LuCI ---> Applications ---> luci-app-sqm #流量智能队列管理（QOS）
###### LuCI ---> Applications ---> luci-app-squid #Squid代理服务器
###### LuCI ---> Applications ---> luci-app-statistics #流量监控工具
###### LuCI ---> Applications ---> luci-app-syncdial #多拨虚拟网卡（原macvlan）
###### LuCI ---> Applications ---> luci-app-tinyproxy #Tinyproxy是 HTTP(S)代理服务器
###### LuCI ---> Applications ---> luci-app-transmission #BT下载工具
###### LuCI ---> Applications ---> luci-app-travelmate #旅行路由器
###### LuCI ---> Applications ---> luci-app-ttyd #网页终端命令行
###### LuCI ---> Applications ---> luci-app-udpxy #udpxy做组播服务器
###### LuCI ---> Applications ---> luci-app-uhttpd #uHTTPd Web服务器
###### LuCI ---> Applications ---> luci-app-unblockmusic #解锁网易云灰色歌曲
###### LuCI ---> Applications ---> luci-app-unblockneteasemusic-go #解锁网易云歌曲 *
###### LuCI ---> Applications ---> luci-app-unbound #Unbound DNS解析器
###### LuCI ---> Applications ---> luci-app-upnp #通用即插即用UPnP（端口自动转发）
###### LuCI ---> Applications ---> luci-app-usb-printer #USB 打印服务器
###### LuCI ---> Applications ---> luci-app-verysync #微力同步 *
###### LuCI ---> Applications ---> luci-app-vlmcsd #KMS服务器设置
###### LuCI ---> Applications ---> luci-app-vnstat #vnStat网络监控（图表）
###### LuCI ---> Applications ---> luci-app-vsftpd #FTP服务器
###### LuCI ---> Applications ---> luci-app-watchcat #断网检测功能与定时重启
###### LuCI ---> Applications ---> luci-app-webadmin #Web管理页面设置
###### LuCI ---> Applications ---> luci-app-wxedge #网心云
###### LuCI ---> Applications ---> luci-app-webshell #网页命令行终端（已弃）
###### LuCI ---> Applications ---> luci-app-wifischedule #WiFi 计划
###### LuCI ---> Applications ---> luci-app-wireguard #virtual**服务器 WireGuard状态
###### LuCI ---> Applications ---> luci-app-wol #WOL网络唤醒
###### LuCI ---> Applications ---> luci-app-wrtbwmon #实时流量监测
###### LuCI ---> Applications ---> luci-app-xlnetacc #迅雷快鸟
###### LuCI ---> Applications ---> luci-app-zerotier #ZeroTier内网穿透
###### LuCI ---> Applications ---> luci-app-homeassistant #智能家居
###### LuCI ---> Applications ---> luci-app-homebox #内网测速
###### [luci-app-gowebdav](#/README.md) &emsp;&emsp; # GoWebDav 是一个轻巧、简单、快速的 WebDav 服务端程序
###### [luci-app-ipsec-vpnserver-manyusers](#/README.md) &emsp;&emsp; # ipsec-vpn
###### [luci-app-iptvhelper](#/README.md) &emsp;&emsp; # iptvhelper,帮助你轻松配置IPTV
###### [luci-app-linkease](#/README.md) &emsp;&emsp; # 易有云文件管理器
###### [luci-app-k3screenctrl](#/README.md) &emsp;&emsp; # K3屏幕
###### [luci-app-koolddns](#/README.md) &emsp;&emsp; # 支持阿里DDNS、DnsPod动态域名解析
###### [luci-app-mentohust](#/README.md) &emsp;&emsp; # 锐捷验证
###### [luci-app-netdata](#/README.md) &emsp;&emsp; # 实时监控中文版
###### [luci-app-netkeeper-interception](#/README.md) &emsp;&emsp; # 闪讯拦截,闪讯拨号
###### [luci-app-oaf](#/README.md) &emsp;&emsp; # 应用过滤
###### [luci-app-onliner](#/README.md) &emsp;&emsp; # 流量监控
###### [luci-app-openclash](#/README.md) &emsp;&emsp; # openclash
###### [luci-app-oscam](#/README.md) &emsp;&emsp; # OSCAM服务器
###### [luci-app-poweroff](#/README.md) &emsp;&emsp; # 关机
###### [luci-app-pppoe-server](#/README.md) &emsp;&emsp; # 宽带接入认证服务器
###### [luci-app-pushbot](#/README.md) &emsp;&emsp; # 钉钉推送（微信推送修改版）
###### [luci-app-rebootschedule](#/README.md) &emsp;&emsp; # 多功能定时任务（重启网络、重启系统、重启WIFI、重新拨号...）
###### [luci-app-serverchan](#/README.md) &emsp;&emsp; # 微信推送
###### [luci-app-smartdns](#/README.md) &emsp;&emsp; # smartdns
###### [luci-app-smartinfo](#/README.md) &emsp;&emsp; # 穿越蓝天磁盘监控
###### [luci-app-socat](#/README.md) &emsp;&emsp; # 多功能的网络工具
###### [luci-app-switch-lan-play](#/README.md) &emsp;&emsp; # 虚拟局域网联机工具
###### [luci-app-syncthing](#/README.md) &emsp;&emsp; # syncthing同步工具
###### [luci-app-tencentddns](#/README.md) &emsp;&emsp; # 腾讯DDNS
###### [luci-app-timecontrol](#/README.md) &emsp;&emsp; # 时间控制跟（luci-app-accesscontrol）差不多，不同的是这个可以配合高级设置一起使用
###### [luci-app-ttnode](#/README.md) &emsp;&emsp; # 甜糖星愿自动采集插件
###### [luci-theme-argon](#/README.md) &emsp;&emsp; # argon主题
###### [luci-theme-atmaterial](#/README.md) &emsp;&emsp; # atmaterials三合一主题
###### [luci-theme-edge](#/README.md) &emsp;&emsp; # edge主题
###### [luci-theme-infinityfreedom](#/README.md) &emsp;&emsp; # infinityfreedom主题
###### [luci-theme-opentomato](#/README.md) &emsp;&emsp; # opentomato主题
###### [luci-theme-opentomcat](#/README.md) &emsp;&emsp; # opentomcat主题
###### [luci-theme-rosy](#/README.md) &emsp;&emsp; # rosy主题
###### [luci-theme-darkmatter](#/README.md) &emsp;&emsp; # 黑色主题
#

#
```
luci-app-samba 和 luci-app-samba4 不能同时编译，同时编译会失败

想选择luci-app-samba4，首先在Extra packages ---> 把autosamba取消，在选择插件的那里把luci-app-samba取消，
然后在Network ---> 把 samba36-server取消，最后选择luci-app-samba4，记得顺序别搞错
```
```
luci-app-dockerman 和 luci-app-docker 不能同时编译，同时编译会编译失败

想要编译luci-app-dockerman或者luci-app-docker

首先要在Global build settings ---> Enable IPv6 support in packages (NEW)（选上）
```
```
luci-app-ddnsto  如果有兼容性问题，安装好固件后执行 /etc/init.d/ddnsto enable 命令
```
```
luci-app-advanced  已内置luci-app-fileassistant文件助手，切莫同时编译他们
```
#
#
##### 如果您是配合我的仓库一起使用的话，这里没有你需要的插件，请不要一下子就拉取别人的插件包
##### 相同的文件都拉一起，因为有一些可能还是其他大神修改过的容易造成编译错误的
##### 想要什么插件就单独的拉取什么插件就好，或者告诉我，我把插件放我的插件包就行了

#
#
## 感谢各位大神的源码，openwrt有各位大神而精彩，感谢！感谢！，插件每天白天12点跟晚上12点都同步一次各位大神的源码！

#

# 请不要Fork此仓库，你Fork后，插件不会自动根据作者更新而更新!!!!!!!!!!!
