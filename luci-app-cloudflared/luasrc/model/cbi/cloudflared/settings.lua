
a=Map("cloudflared",translate("Cloudflared"),translate("Cloudflare的隧道客户端 - 以前称为 Argo Tunnel ，免费的内网穿透，实现内网服务的外网访问"))
a:section(SimpleSection).template  = "cloudflared/cloudflared_status"

t=a:section(NamedSection,"config","cloudflared")
t.anonymous=true
t.addremove=false

e=t:option(Flag,"enabled",translate("Enable"))
e.default=0
e.rmempty=false

o = t:option(Button, "btnrm", translate("版本"))
o.inputtitle = translate("检测更新")
o.description = translate("点击按钮开始检测更新，上方状态栏显示")
o.inputstyle = "apply"
o:depends("enabled", "1")
o.write = function()
  os.execute("rm -rf /tmp/cloudflared*.tag /tmp/cloudflared*.newtag")
end

e=t:option(Flag,"cmdenabled",translate("自定义启动参数"),
	translate("使用自定义的启动参数，若不懂请勿开启"))
e.default=0
e.rmempty=false

cfbin = t:option(Value, "cfbin", translate("cloudflared程序路径"),
	translate("自定义cloudflared的存放路径,确保填写完整的路径及cloudflared名称"))
cfbin.placeholder = "/usr/bin/cloudflared"
cfbin.rmempty=false

e=t:option(DynamicList,"token",translate('隧道 Token'),
	translate("需要先去官网创建隧道，再复制以eyJh开头的一长串token值，注意复制正确否则会启动失败<br>关于没有信用卡可以使用命令创建隧道 ：<a href='https://blog.outv.im/2021/cloudflared-tunnel/' target='_blank'>教程1</a>&nbsp;&nbsp;&nbsp;<a href='https://zhuanlan.zhihu.com/p/621870045' target='_blank'>教程2</a>"))
e.placeholder = "eyJhIjoiMzQ3NTNhNDBlZTg4NTYzMDU5YmUzN2U2ZDY4YjEzY2QiLCJ0IjoiNTJkMjkwYTktNmFiNy00NDM5LThlODYtMzhmYTI0NTBhZjNhIiwicyI6IlptRXlOekl4TURZdFpUa3dPUzAwTnprM0xUbGlaR1l0TWpNNVpUUTBNV0k0TTJNMSJ9"
e:depends("cmdenabled", 0)

custom_cmd = t:option(DynamicList, "custom_cmd", translate("自定义启动参数"),
                       translate("这里不需要再加程序路径，只需要正常添加启动参数即可，详细的命令启动参数：<a href='https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/tunnel-run-parameters/' target='_blank'>cloudflared文档</a><br>注意:每个参数必须单独添加,如添加第一个参数tunnel 第二个参数--no-autoupdate 第三个参数--logfile /tmp/cloudflared.info 第四个参数run <br>一个框内不能添加两个参数,多个参数点+多个框即可<br>如需输出日志路径请设置 --logfile /tmp/cloudflared.info"))
custom_cmd.placeholder = "--logfile /tmp/cloudflared.info"
custom_cmd:depends("cmdenabled", 1)

loglevel = t:option(ListValue, "loglevel", translate("日志等级"),
	translate("指定日志记录的详细程度。默认info级别不会产生太多输出，但您可能希望warn在生产中使用该级别。<br>等级由低到高：debug < info < warn < Error < Fatal"))
loglevel:value("info")
loglevel:value("debug")
loglevel:value("warn")
loglevel:value("error")
loglevel:value("fatal")
loglevel:depends("cmdenabled", 0)


e=t:option(DummyValue,"opennewwindow" , 
	translate("<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"cloudflare.com\" onclick=\"window.open('https://one.dash.cloudflare.com')\" />"))
e.description = translate("进入官网Zero Trust创建或管理您的 cloudflared 隧道")

return a
