require("luci.tools.webadmin")

local fs   = require "nixio.fs"
local util = require "nixio.util"
local tp   = require "luci.template.parser"
local uci=luci.model.uci.cursor()
  -- get all device names (sdX and mmcblkX)
  local target_devnames = {}
  for dev in fs.dir("/dev") do
    if dev:match("^sd[a-z]$")
      or dev:match("^mmcblk%d+$")
      or dev:match("^sata[a-z]$")
      or dev:match("^nvme%d+n%d+$")
      then
      table.insert(target_devnames, dev)
    end
  end
  local devices = {}
  for i, bname in pairs(target_devnames) do
    local device_info = {}
    local device = "/dev/" .. bname
    device_info["name"] = bname
    device_info["dev"] = device

    s = tonumber((fs.readfile("/sys/class/block/%s/size" % bname)))
    device_info["size"] = s and math.floor(s / 2048)

    devices[#devices+1] = device_info
end

local m,t,e
m = Map("partexp", "<font color='green'>" .. translate("Partition expansion") .."</font>",
translate( "Automatically format the target device partition. If there are multiple partitions, it is recommended to manually delete all partitions before using this tool.<br/>For specific usage, see:") ..translate("<a href=\'https://github.com/sirpdboy/luci-app-partexp.git' target=\'_blank\'>GitHub</a>") )

t=m:section(TypedSection,"global")
t.anonymous=true

e=t:option(ListValue,"target_function", translate("Select function"),translate("Select the function to be performed"))
e:value("/overlay", translate("Expand application space overlay (/overlay)"))
e:value("/", translate("Use as root filesystem (/)"))
e:value("/opt", translate("Used as Docker data disk (/opt)"))

-- local disks = dm.list_disks()
e=t:option(ListValue,"target_disk", translate("Destination hard disk"),translate("Select the hard disk device to operate"))
for i, d in ipairs(devices) do
	if d.name and d.size then
		e:value(d.name, "%s (%s, %d MB)" %{ d.name, d.dev, d.size })
	elseif d.name then
		e:value(d.name, "%s (%s)" %{ d.name, d.dev })
	end
end

o=t:option(Flag,"keep_config",translate("Keep configuration"))
o:depends("target_function", "/overlay")
o.default=1

o=t:option(Flag,'auto_format', translate('Format before use'))
o.default=1

o = t:option(DummyValue, '', '')
o.rawhtml = true
o.template ='partexp'

-- e =t:option(DummyValue, '', '')
-- e.rawhtml = true
-- e.template = 'partexp/log'

return m
