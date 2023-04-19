## luci-app-netspeedtest

### 访问数：[![](https://visitor-badge.glitch.me/badge?page_id=sirpdboy-visitor-badge)] [![](https://img.shields.io/badge/TG群-点击加入-FFFFFF.svg)](https://t.me/joinchat/AAAAAEpRF88NfOK5vBXGBQ)

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/说明1.jpg)

luci-app-netspeedtest 网络速度诊断测试（包括：内网网页版测速、内网iperf3吞吐测速、外网speedtest.net网速测试、特定服务器的端口延迟测速）

[luci-app-netspeedtest 网络速度诊断测试](https://github.com/sirpdboy/netspeedtest)

请 **认真阅读完毕** 本页面，本页面包含注意事项和如何使用。

## 写在前面

 - 一直在找OPENWRT上测试速度的插件，苦寻不到，于是有了它! 此插件可进行内外和外网网络速度测试。
 - TG群友说插件2年没更新了，花了几天时间结合时下需要，将网络测试功能升级到2.0版本。

<!-- TOC -->

## [菜单向导](#luci-app-netspeedtest)
  - [功能说明](#功能说明)
  - [注意事项](#iperf3吞吐测试注意事项)
  - [版本说明](#版本说明)
  - [使用方法](#使用方法)
  - [源码说明](#源码说明)
  - [界面](#界面)
  - [其它](#其它)
  - [感谢](#感谢)
  - [捐助](#捐助)
  
<!-- /TOC -->

## 功能说明
- 内网网页版测速插件 ：基于speedtest-web网页版，启用后再点start进行测速。网页版启动后程序会驻留内存不测速建议不启用服务。
- 内网iperf3吞吐测试 ，服务端路由器如果没有安装请先安装此iperf3插件。
- 外网测速使用speedtest.net测速内核，基于speedtest-cli,需要有python3才能执行。
- 特定服务器的端口延迟测速，是测试指定服务器的端口的延迟情况。

## iperf3吞吐测试注意事项
- 测速的终端使用机器必须和测速服务器在同一个局域网络中！
- 客户端使用步骤：启动测速服务器端-->下载测试客户端-->运行测速客户端-->输入服务端IP地址-->查看结果。
- 客户端运行，国内端下载中有“iperf3测速客户端”，运行它输入服务器IP即可。
  国外原版，需要手动进入 CMD命令模式，再输入命令：iperf3.exe -c 服务器IP 
- 网络测速iperf3客户端下载地址：https://sipdboy.lanzoui.com/b01c3esih 密码:cpd6
- 需要依赖： python3 iperf3 speedtest-web

## 版本说明


### 2023.3.2  网速测试V2.1.3：
   - 修复测速Speedtest看不到测试报名问题。
   - 重新调试IPERF3测试页面代码，解决某些主题显示不优雅的问题。
   - 修复取消服务自动启用的问题
   
### 2023.1.15  网速测试V2.1：
   - 内网测试速度WEB页采用homebox。
   - 修复WEB页内网测试自动启用问题。
   - 外网测速加入Netperf测试。
   - 外网测速Speedtest某些节点会禁止测速。要测速建议关了留国的插件。

### 2022.10.18  网速测试V2.0.3：
   - 代码基本重写和优化。
   - Iperf3可实时体现服务状态。
   - 增加内网测试网页版。
   - 外网测速，加入更详细测试报告。
   
### 2021.3.2  网速测试V1.6：
   - 升级宽带测试带2.13内核。
   - 解决1.806以上版本不能编译问题。
   
## 使用方法

将NetSpeedTest 主题添加至 LEDE/OpenWRT 源码的方法。 

### 下载源码：
 
    # 下载源码
	
    git clone https://github.com/sirpdboy/netspeedtest.git package/netspeedtest
    make menuconfig
	
 ``` 
### 配置菜单

 ```Brach
    make menuconfig
	# 找到 LuCI -> Applications, 选择 luci-app-netspeedtest, 保存后退出。
 ``` 
 
### 编译

 ```Brach 
    # 编译固件
    make package/netspeedtest/luci-app-netspeedtest/compile V=s
 ```


## 源码说明

- 源码来源和依赖:
- luci-app-netspeedtest：https://github.com/sirpdboy/netspeedtest
- speedtest-web：https://github.com/ZeaKyX/speedtest-web
- speedtest-cl：https://github.com/sivel/speedtest-cli

- 你可以随意使用其中的源码，但请注明出处。

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/说明2.jpg)

## 界面

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/netspeedtest1.jpg)

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/netspeedtest2.jpg)

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/netspeedtest3.jpg)

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/netspeedtest4.jpg)



## 使用与授权相关说明
 
- 本人开源的所有源码，任何引用需注明本处出处，如需修改二次发布必告之本人，未经许可不得做于任何商用用途。


# My other project

- 网络速度测试 ：https://github.com/sirpdboy/NetSpeedTest

- 定时设置插件 : https://github.com/sirpdboy/luci-app-autotimeset

- 关机功能插件 : https://github.com/sirpdboy/luci-app-poweroffdevice

- opentopd主题 : https://github.com/sirpdboy/luci-theme-opentopd

- kucat 主题: https://github.com/sirpdboy/luci-theme-kucat

- 家长控制: https://github.com/sirpdboy/luci-theme-parentcontrol

- 系统高级设置 : https://github.com/sirpdboy/luci-app-advanced

- ddns-go动态域名: https://github.com/sirpdboy/luci-app-ddns-go

- 进阶设置（系统高级设置+主题设置kucat/agron/opentopd）: https://github.com/sirpdboy/luci-app-advancedplus

- 设置向导: https://github.com/sirpdboy/luci-app-wizard

- 分区扩容: https://github.com/sirpdboy/luci-app-partexp

- lukcy大吉: https://github.com/sirpdboy/luci-app-lukcy

## 捐助

![screenshots](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/说明3.jpg)

|     <img src="https://img.shields.io/badge/-支付宝-F5F5F5.svg" href="#赞助支持本项目-" height="25" alt="图飞了😂"/>  |  <img src="https://img.shields.io/badge/-微信-F5F5F5.svg" height="25" alt="图飞了😂" href="#赞助支持本项目-"/>  | 
| :-----------------: | :-------------: |
|![xm1](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/支付宝.png) | ![xm1](https://raw.githubusercontent.com/sirpdboy/openwrt/master/doc/微信.png) |

<a href="#readme">
    <img src="https://img.shields.io/badge/-返回顶部-orange.svg" alt="图飞了😂" title="返回顶部" align="right"/>
</a>
