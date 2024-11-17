m = Map("gxu-webconnect", "GXU网络认证插件")
m.description = translate("本插件用于给广西大学学生设置路由器登录校园网，支持开机自启，断网重登。<br />在本页面填入你的上网账号和密码，选择运营商。<br />其他学校也可以自行修改路由器/etc/gxuwc.sh文件适配")

m:section(SimpleSection).template  = "gxu-webconnect/gxuwc_status"

s = m:section(TypedSection, "gxu-webconnect")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enable", translate("启用"))
enable.rmempty = false
enable.description = translate("勾选启用保存并应用后会尝试登录，取消勾选再保存并应用则不会注销")

id = s:option(Value, "id", translate("账号"))
id.description = translate("填入你的上网账号，即你的学号")

password = s:option(Value, "password", translate("密码"))
password.description = translate("填入你的上网密码，默认为身份证后六位<br />本插件不对密码做保护，请个人注意")

web_provier = s:option(ListValue, "web_provier", translate("运营商"))
web_provier:value("0", translate("校园网"))
web_provier:value("1", translate("移动"))
web_provier:value("2", translate("联通"))
web_provier:value("3", translate("电信"))
web_provier.default = "0"

delay = s:option(Value, "delay", translate("检查断网间隔"))
delay.default = "60"
delay.description = translate("指定时间间隔检测网络状态，单位为秒<br />检测到断网则尝试重新登录")

reconnect = s:option(Button, "reconnect","手动重登")
reconnect.inputtitle = translate("重新登录")
reconnect.inputstyle = "reload"
function reconnect.write(self, section)
	io.popen("/etc/gxuwc.sh Login")
end

return m