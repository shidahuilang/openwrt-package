# [[281677160/build-actions的专用软件包](https://github.com/281677160/build-actions)]

#
#### [master]分支的为[[lede_source](https://github.com/coolsnowwolf/lede)]源码专用
#### [19.07]分支的为[[lienol_source](https://github.com/Lienol/openwrt)]源码专用
#### [openwrt-21.02]分支的为[[Mortal_source](https://github.com/immortalwrt/immortalwrt)]源码专用
#### 为什么要这样分开呢？因为每个源码作者习惯都不一样，有些源码带了某插件，有些源码又没带，我是尽量的做到源码自带的就用源码自带的，源码没带的就加入，这样就不会重覆了，减少编译错误的概率。
#

##### 添加以下插件
###### [luci-app-adblock-plus](#/README.md) &emsp;&emsp; # 拦截广告
###### [luci-app-adguardhome](#/README.md) &emsp;&emsp; # adguardhome
###### [luci-app-advanced](#/README.md) &emsp;&emsp; # 高级设置（内置luci-app-fileassistant文件助手）
###### [luci-app-aliddns](#/README.md) &emsp;&emsp; # 阿里DDNS
###### [luci-app-amlogic](#/README.md) &emsp;&emsp; # N1和晶晨系列盒子写入EMMC插件
###### [luci-app-argon-config](#/README.md) &emsp;&emsp; # argon主题设置,要配合argon主题使用
###### [luci-app-clash](#/README.md) &emsp;&emsp; # clash
###### [luci-app-control-timewol](#/README.md) &emsp;&emsp; # 定时网络设备唤醒
###### [luci-app-control-webrestriction](#/README.md) &emsp;&emsp; # 访问限制
###### [luci-app-control-weburl](#/README.md) &emsp;&emsp; # 网址过滤
###### [luci-app-cpulimit](#/README.md) &emsp;&emsp; # CPU性能调整
###### [luci-app-cupsd](#/README.md) &emsp;&emsp; # CUPS 打印服务器
###### [luci-app-ddnsto](#/README.md) &emsp;&emsp; # 内网穿透
###### [luci-app-dockerman](#/README.md) &emsp;&emsp; # docker附带控制面板
###### [luci-app-eqos](#/README.md) &emsp;&emsp; # 网速限制
###### [luci-app-filebrowser](#/README.md) &emsp;&emsp; # 文件管理器
###### [luci-app-godproxy](#/README.md) &emsp;&emsp; # 拦截广告
###### [luci-app-gost](#/README.md) &emsp;&emsp; # GO语言实现的安全隧道
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
##### 《[单独拉取插件说明](https://github.com/danshui-git/shuoming/blob/master/ming.md)》 ，里面包含各种命令简单说明
#
#
## 感谢各位大神的源码，openwrt有各位大神而精彩，感谢！感谢！，插件每天白天12点跟晚上12点都同步一次各位大神的源码！

#

# 请不要Fork此仓库，你Fork后，插件不会自动根据作者更新而更新!!!!!!!!!!!
