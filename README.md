##### 添加以下插件
###### luci-theme-rosy    &nbsp;&nbsp;&nbsp;&nbsp;#主题-rosy
###### luci-theme-edge    &nbsp;&nbsp;&nbsp;&nbsp;#主题-edge
###### luci-theme-opentomcat   &nbsp;&nbsp;&nbsp;&nbsp;#主题-opentomcat
###### luci-theme-opentopd   &nbsp;&nbsp;&nbsp;&nbsp;#主题-opentopd<br>
###### luci-theme-rosy   &nbsp;&nbsp;&nbsp;&nbsp;#主题-rosy<br>
###### luci-theme-atmaterial   &nbsp;&nbsp;&nbsp;&nbsp;#atmaterial-主题<br>
###### luci-theme-infinityfreedom    &nbsp;&nbsp;&nbsp;&nbsp;#透明主题<br>
###### [luci-app-advanced](#/README.md)   &nbsp;&nbsp;&nbsp;&nbsp;#[luci-app-advanced&nbsp;高级设置&nbsp;+&nbsp;luci-app-filebrowser&nbsp;文件浏览器（文件管理）](#/README.md)<br>
###### luci-app-serverchan    &nbsp;&nbsp;&nbsp;&nbsp;#微信推送<br>
###### luci-app-eqos    &nbsp;&nbsp;&nbsp;&nbsp;#内网控速 内网IP限速工具<br>
###### luci-app-jd-dailybonus    &nbsp;&nbsp;&nbsp;&nbsp;#京东签到<br>
###### luci-app-poweroff    &nbsp;&nbsp;&nbsp;&nbsp;#关机（增加关机功能）<br>
###### luci-theme-argon    &nbsp;&nbsp;&nbsp;&nbsp;#新的argon主题<br>
###### luci-app-argon-config    &nbsp;&nbsp;&nbsp;&nbsp;#argon主题设置（编译时候选上,在固件的‘系统’里面）<br>
###### luci-app-k3screenctrl   &nbsp;&nbsp;&nbsp;&nbsp;#k3屏幕，k3路由器专用<br>
###### luci-app-koolproxyR   &nbsp;&nbsp;&nbsp;&nbsp;#广告过滤大师 plus+  ，慎用，不懂的话，打开就没网络了<br>
###### luci-app-oaf   &nbsp;&nbsp;&nbsp;&nbsp;#应用过滤 ，该模块只工作在路由模式， 旁路模式、桥模式不生效，还有和Turbo ACC 网络加速有冲突<br>
###### luci-app-gost   &nbsp;&nbsp;&nbsp;&nbsp;#GO语言实现的安全隧道<br>
###### luci-app-cpulimit   &nbsp;&nbsp;&nbsp;&nbsp;#CPU性能限制<br>
###### luci-app-wrtbwmon-zhcn   &nbsp;&nbsp;&nbsp;&nbsp;#流量统计，替代luci-app-wrtbwmon，在固件状态栏显示<br>
###### luci-app-smartdns   &nbsp;&nbsp;&nbsp;&nbsp;#smartdns DNS加速<br>
###### luci-app-modeminfo    &nbsp;&nbsp;&nbsp;&nbsp;#OpenWrt LuCi的3G / LTE加密狗信息<br>
###### [luci-app-mentohust]   &nbsp;&nbsp;&nbsp;&nbsp;#MentoHUST 的 LuCI 控制界面<br>
###### luci-app-gowebdav   &nbsp;&nbsp;&nbsp;&nbsp;#GoWebDav 是一个轻巧、简单、快速的 WebDav 服务端程序<br>
###### luci-app-smartinfo   &nbsp;&nbsp;&nbsp;&nbsp;#磁盘监控 ，该工具帮助您通过S.M.A.R.T技术来监控您硬盘的健康状况<br>
#
##### 如果lede那个插件包有这里又没有的插件，那就代表源码已自带了，不需要再添加，所以看说明在master分支看就好了
#
#

- 编译luci-app-advanced时候同时会带上luci-app-filebrowser的，所以luci-app-advanced 和 luci-app-filebrowser 不能同时编译，同时编译会失败
- luci-app-samba 和 luci-app-samba4 不能同时编译，同时编译会失败
#
#
##### 如果还是没有你需要的插件，请不要一下子就拉取别人的插件包
##### 相同的文件都拉一起，因为有一些可能还是其他大神修改过的容易造成编译错误的
##### 想要什么插件就单独的拉取什么插件就好，或者告诉我，我把插件放我的插件包就行了
