local fs = require "nixio.fs"
local sys = require "luci.sys"
m = Map("nettask", translate("openwrt自定义shell脚本"), translate(
    "这是一个由用户自由编写shell脚本的界面工具，它支持立即执行、开机执行、定时执行、按下物理按键时执行，执行系统命令时确保不会对系统造成影响！！！<br><a href='https://www.yuque.com/mschool/akifsq/tply0gh1p17k7cu5?singleDoc# 《网页抓包认证方法》' target='_blank' style='color: lightblue;'>您对此插件有疑问？点此转到教程：https://www.yuque.com/g/mschool/akifsq/tply0gh1p17k7cu5/collaborator/join?token=kM5RSN3g7g8RRiCI&source=doc_collaborator# 《网页抓包认证方法》</a>"))
s = m:section(TypedSection, "nettask")
s.anonymous = true

s:tab("config", translate("立刻执行"), translate("单击下方按钮即可立即运行/停止脚本，支持死循环，但是需要避免空操作，以免造成资源浪费！！"))
conf1 = s:taboption("config", Value, "editconf", nil, translate(
    "温馨提示：#号后面的内容为注释，如果对脚本进行了修改（或首次编辑），请先保存后再运行"))
conf1.template = "cbi/tvalue"
conf1.rows = 20
conf1.wrap = "off"
function conf1.cfgvalue(self, section)
    return fs.readfile("/etc/nettask/duan.sh") or ""
end

function conf1.write(self, section, value)
    if value then
        value = value:gsub("\r\n?", "\n")
        fs.writefile("/tmp/duan.sh", value)
        if (luci.sys.call("cmp -s /tmp/duan.sh /etc/nettask/duan.sh") == 1) then
            fs.writefile("/etc/nettask/duan.sh", value)
        end
        fs.remove("/tmp/duan.sh")
    end
end
local pid = luci.sys.exec("pgrep -f '/etc/nettask/duan.sh'")

if pid == "" then
    detect = s:taboption("config", Button, "block_detect", translate("执行脚本"),
        translate("按下立刻执行脚本"))
    detect.inputstyle = "reload"

    function detect.write()
        luci.sys.call("sh /etc/nettask/duan.sh &")
        luci.http.redirect(luci.dispatcher.build_url("admin", "system", "NetTask"))
    end
else
    detect = s:taboption("config", Button, "block_detect", translate("停止脚本"),
        translate("按下立刻停止脚本"))
    detect.inputstyle = "reload"

    function detect.write()
        luci.sys.call("pgrep -f /etc/nettask/duan.sh | xargs kill -9 >/dev/null 2>&1")
        luci.http.redirect(luci.dispatcher.build_url("admin", "system", "NetTask"))
    end

end

s:tab("config2", translate("启动时执行"), translate("此脚本在系统启动时自动执行（可选）"))

conf2 = s:taboption("config2", Value, "nertu", nil, translate(
    "温馨提示：保存后此脚本会立即运行一次，而后只会在系统启动初始化阶段运行"))
conf2.template = "cbi/tvalue"
conf2.rows = 20
conf2.wrap = "off"
function conf2.cfgvalue(self, section)
    return fs.readfile("/etc/nettask/word.sh") or ""
end

function conf2.write(self, section, value)
    if value then
        value = value:gsub("\r\n?", "\n")
        fs.writefile("/tmp/word.sh", value)
        if (luci.sys.call("cmp -s /tmp/word.sh /etc/nettask/word.sh") == 1) then
            fs.writefile("/etc/nettask/word.sh", value)
        end
        fs.remove("/tmp/word.sh")
    end
end

k1 = s:taboption("config2", Flag, "word", translate("启用脚本"), translate("取消时将停用该脚本"))

s:tab("config3", translate("按下按钮时执行"), translate("当前插件会覆盖默认按钮事件，短按按钮执行此脚本（注意：轻按一下快速松开即可，不要超过1秒，否则会重启路由器，超过五秒会重置路由器！！）"))

conf3 = s:taboption("config3", Value, "editcon", nil, translate(
    "温馨提示：#号后面的内容为注释，如果对脚本进行了修改（或首次编辑），请先保存后再运行"))
conf3.template = "cbi/tvalue"
conf3.rows = 20
conf3.wrap = "off"
function conf3.cfgvalue(self, section)
    return fs.readfile("/etc/nettask/button.sh") or ""
end

function conf3.write(self, section, value)
    if value then
        value = value:gsub("\r\n?", "\n")
        fs.writefile("/tmp/button.sh", value)
        if (luci.sys.call("cmp -s /tmp/button.sh /etc/nettask/button.sh") == 1) then
            fs.writefile("/etc/nettask/button.sh", value)
        end
        fs.remove("/tmp/button.sh")
    end
end

k2 = s:taboption("config3", Flag, "button", translate("启用脚本"), translate("取消时将停用该脚本"))

s:tab("config4", translate("断网时执行"), translate("此脚本在网络断开时执行（可选），此脚本应该注意避免死循环，否则可能会反复创建进程"))

conf4 = s:taboption("config4", Value, "networ", nil, translate(
    "温馨提示：#号后面的内容为注释，如果对脚本进行了修改（或首次编辑），请先保存后再运行"))
conf4.template = "cbi/tvalue"
conf4.rows = 20
conf4.wrap = "off"
function conf4.cfgvalue(self, section)
    return fs.readfile("/etc/nettask/network.sh") or ""
end

function conf4.write(self, section, value)
    if value then
        value = value:gsub("\r\n?", "\n")
        fs.writefile("/tmp/network.sh", value)
        if (luci.sys.call("cmp -s /tmp/network.sh /etc/nettask/network.sh") == 1) then
            fs.writefile("/etc/nettask/network.sh", value)
        end
        fs.remove("/tmp/network.sh")
    end
end

k3 = s:taboption("config4", Flag, "network", translate("启用脚本"), translate("取消时将停用该脚本"))
f3 = s:taboption("config4", Value, "nettime", translate("时间间隔(秒)"),
    translate("您希望多久检测一次网络状态?<br>提示：此值应为>=1的整数"))
f3.default = "30"

s:tab("config5", translate("定时执行"), translate("此脚本在规定时间内执行（可选），此脚本应该注意避免死循环，否则可能会反复创建进程"))

conf5 = s:taboption("config5", Value, "crcode", nil, translate(
    "温馨提示：#号后面的内容为注释，如果对脚本进行了修改（或首次编辑），请先保存后再运行"))
conf5.template = "cbi/tvalue"
conf5.rows = 20
conf5.wrap = "off"
function conf5.cfgvalue(self, section)
    return fs.readfile("/etc/nettask/timing.sh") or ""
end

function conf5.write(self, section, value)
    if value then
        value = value:gsub("\r\n?", "\n")
        fs.writefile("/tmp/timing.sh", value)
        if (luci.sys.call("cmp -s /tmp/timing.sh /etc/nettask/timing.sh") == 1) then
            fs.writefile("/etc/nettask/timing.sh", value)
        end
        fs.remove("/tmp/timing.sh")
    end
end

k4 = s:taboption("config5", Flag, "timi", translate("启用脚本"), translate("取消时将停用该脚本"))
f4 = s:taboption("config5", Value, "minute", translate("分（0~59）"))
f4.default = "0"
f5 = s:taboption("config5", Value, "shi", translate("时（0~23）"))
f5.default = "8"
f6 = s:taboption("config5", Value, "day", translate("日（1~31）"))
f6.default = "*"
f7 = s:taboption("config5", Value, "month", translate("月（1~12）"))
f7.default = "*"
f8 = s:taboption("config5", Value, "week", translate("周（1~7）"), translate(
    "在以上输入框中，您可以输入指定时间来定时运行脚本。如果不想指定特定值，可以使用 '*' 表示 '任何数'。<br><br>以下是一些示例：<br><br>- 如果周的值为 '*'，则表示每周的每天指定时间都会执行脚本。<br>- 您可以指定多个值或范围，使用逗号分隔多个指定值。例如，周的值为 '1,2,3' 表示每周的周一、周二和周三都会执行脚本。您还可以使用 '-' 表示范围，例如 '1-3' 表示从周一到周三都会执行脚本。<br>- 您还可以使用 '/' 和 '*' 组合来表示某个值需要满足整除关系才执行脚本。例如，分钟的值为 '*/30' 表示每个小时的0分和30分时执行脚本。<br><br>请注意，只有当每个时间条件都满足时，脚本才会执行。同时，请确保使用英文输入法输入所有符号，否则可能无法正常执行。<br>"))
f8.default = "*"

m.on_commit = function(self)
    luci.sys.call("/etc/init.d/nettask start")
end


return m
