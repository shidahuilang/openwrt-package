local m, s
m = Map("caddy", translate("Caddy"), translate("Caddy 是一个可扩展的服务器平台,具有自动 HTTPS 功能的快速且可扩展的多平台 HTTP/1-2-3 Web 服务器") .. "<br/>" .. "项目地址：" .. [[<a href="https://github.com/caddyserver/caddy" target="_blank">]] .. translate("github.com/caddyserver/caddy") .. "</a>&nbsp; &nbsp;&nbsp;" .. " caddy文档：" .. [[<a href="https://caddyserver.com/docs/" target="_blank">]] .. translate("caddyserver.com/docs/") .. [[</a>]])

m:section(SimpleSection).template  = "caddy/caddy_status"

s = m:section(TypedSection, "caddy")
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enabled"))
o.rmempty = false
o.default = 0

o = s:option(Button, "btnrm", translate("版本"))
o.inputtitle = translate("检测更新")
o.description = translate("点击按钮开始检测更新，上方状态栏显示")
o.inputstyle = "apply"
o:depends("enabled", "1")
o.write = function()
  os.execute("rm -rf /tmp/caddy*.tag /tmp/caddy*.newtag")
end

e=s:option(ListValue,"cmd",translate("启动方式"),
	translate("自定义配置文件启动，若不懂参数请勿选择自定义"))
e:value("默认")
e:value("自定义")

o = s:option(TextValue, "caddyfile", translate("Caddyfile配置文件"),
	translate("这是caddy的启动配置文件Caddyfile，路径在/etc/caddy/Caddyfile<br>使用的命令是：caddy run --config /etc/caddy/Caddyfile --adapter caddyfile<br>如需设置密码，这里就不能使用明文密码，需要转换<br>转换命令：$(uci -q get caddy.@caddy[0].bin_dir) hash-password  --plaintext 新密码"))
o.rows = 3
o.wrap = "off"
o:depends("cmd", "自定义")

o = s:option(Value, "port", translate("端口"))
o.datatype = "and(port,min(1))"
o.default = "12311"
o:depends("cmd", "默认")

o = s:option(Flag,"file_pass", translate("启用 认证"))
o.datatype = "string"
o.default = "0"
o:depends("cmd", "默认")

o = s:option(Value,"file_username", translate("用户名"))
o.datatype = "string"
o.default = "admin"
o:depends("file_pass", "1")

o = s:option(Value,"file_password", translate("密码"))
o.datatype = "string"
o.password = true
o.default = "123456"
o:depends("file_pass", "1")

o = s:option(Flag, "filezip", translate("启用 压缩"))
o.default = 0
o:depends("cmd", "默认")

o = s:option(Flag, "log", translate("启用日志"))
o.default = 1
o:depends("cmd", "默认")

o = s:option(Value, "log_dir", translate("日志路径"),
	translate("日志的存放路径,填写完整的路径及日志文件名<br>建议/tmp里,例如：/tmp/caddy/requests.log"))
o.datatype = "string"
o.default = "/tmp/caddy/requests.log"
o:depends("log", "1")

o = s:option(Value, "bin_dir", translate("程序路径"),
	translate("caddy二进制的存放路径,填写完整的路径及caddy名称<br>例如:/usr/bin/caddy  &nbsp;&nbsp;&nbsp; 例如:/tmp/caddy<br>可自行编译对应架构的二进制程序：<a href='https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=6006472&highlight=caddy' target='_blank'>编译教程</a>"))
o.datatype = "string"
o.placeholder = "/usr/bin/caddy"

o = s:option(Value, "data_dir", translate("指向路径"),
	translate("指向一个路径，可在web界面访问你的文件，默认为 /mnt"))
o.datatype = "string"
o.default = "/mnt"
o:depends("cmd", "默认")

o = s:option(Flag, "webdav", translate("启用 webdav"))
o.default = "0"
o:depends("cmd", "默认")

o = s:option(Flag,"webdav_pass", translate("启用 认证"))
o.datatype = "string"
o:depends("webdav", "1")
o.default = "0"

o = s:option(Value,"webdav_username", translate("用户名"))
o.datatype = "string"
o.default = "admin"
o:depends("webdav_pass", "1")

o = s:option(Value,"webdav_password", translate("密码"))
o.datatype = "string"
o.password = true
o.default = "123456"
o:depends("webdav_pass", "1")

o = s:option(Value,"webdav_port", translate("webdav端口"))
o.datatype = "and(port,min(1))"
o.default = "12322"
o:depends("webdav", "1")

o = s:option(Flag, "webzip", translate("启用 压缩"))
o.default = 0
o:depends("webdav", "1")

o = s:option(Value, "webdav_data_dir", translate("webdav指向路径"),
	translate("指向一个路径，使用webdav访问你的文件，默认为 /mnt<br>连接地址须加/dav后缀&nbsp;&nbsp;如： 192.168.1.1:12311/dav"))
o.datatype = "string"
o:depends("webdav", "1")
o.default = "/mnt"

o = s:option(Flag, "allow_wan", translate("允许从外网访问"))
o.rmempty = false

o = s:option(Flag, "api", translate("启用 API接口"))
o:depends("cmd", "默认")

o = s:option(Button, "admin_info", translate("检测配置文件"),
	translate("验证Caddyfile配置文件是否正确，它会模拟启动caddy<br>但是并不会真的启动，会列出详细信息，以便修正配置文件"))

o.rawhtml = true
o.template = "caddy/admin_info"

return m
