local fs = require "luci.fs"
local http = require "luci.http"
local DISP = require "luci.dispatcher"
local b

--Remove the spaces in the string
function trim(str)
   --return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
   return (string.gsub(str, "%s+", ""))
end

--Set Default value
default_firmware_repo="ophub/amlogic-s9xxx-openwrt"
local amlogic_firmware_repo = luci.sys.exec("uci get amlogic.config.amlogic_firmware_repo 2>/dev/null") or default_firmware_repo

default_firmware_tag="s9xxx_lede"
local amlogic_firmware_tag = luci.sys.exec("uci get amlogic.config.amlogic_firmware_tag 2>/dev/null") or default_firmware_tag

default_firmware_suffix=".img.gz"
local amlogic_firmware_suffix = luci.sys.exec("uci get amlogic.config.amlogic_firmware_suffix 2>/dev/null") or default_firmware_suffix

default_kernel_path="amlogic-s9xxx/amlogic-kernel"
local amlogic_kernel_path = luci.sys.exec("uci get amlogic.config.amlogic_kernel_path 2>/dev/null") or default_kernel_path

local default_kernel_branch = luci.sys.exec("ls /lib/modules/ 2>/dev/null | grep -oE '^[1-9].[0-9]{1,3}'")
local amlogic_kernel_branch = luci.sys.exec("uci get amlogic.config.amlogic_kernel_branch 2>/dev/null | grep -oE '^[1-9].[0-9]{1,3}'")
if trim(amlogic_kernel_branch) == "" then
    amlogic_kernel_branch = default_kernel_branch
else
    amlogic_kernel_branch = amlogic_kernel_branch
end

default_firmware_config="1"
local amlogic_firmware_config = luci.sys.exec("uci get amlogic.config.amlogic_firmware_config 2>/dev/null") or default_firmware_config

default_write_bootloader="1"
local amlogic_write_bootloader = luci.sys.exec("uci get amlogic.config.amlogic_write_bootloader 2>/dev/null") or default_write_bootloader

--SimpleForm for Config Source
b = SimpleForm("amlogic_check", translate("Plugin Settings"), nil)
local des_content = translate("You can customize the github.com download repository of OpenWrt files and kernels in [Online Download Update].")
local des_content = des_content .. "<br />" .. translate("Tips: The amlogic SoC (E.g: s905d) and mainline version of the kernel (E.g: 5.13) will automatically match the current openwrt firmware.")
b.description = des_content
b.reset = false
b.submit = false
s = b:section(SimpleSection, "", nil)

--1.Set OpenWrt Firmware Repository
o = s:option(DummyValue, "mydevice", translate("Current Device:"))
o.description = translate("If the current device shows (Unknown device), please report to github.")
o.rmempty = true
o.default = luci.sys.exec("cat /proc/device-tree/model 2>/dev/null") or "Unknown device"

--2.Set OpenWrt Firmware Repository
o = s:option(Value, "firmware_repo", translate("Download repository of OpenWrt:"))
o.description = translate("Set the download repository of the OpenWrt files on github.com in [Online Download Update].")
o.rmempty = true
o.default = amlogic_firmware_repo
o.write = function(self, key, value)
    if value == "" then
        --self.description = translate("Invalid value.")
        amlogic_firmware_repo = default_firmware_repo
    else
        --self.description = translate("Download repository of OpenWrt:") .. value
        amlogic_firmware_repo = value
    end
end

--3.Set OpenWrt Releases's Tag Keywords
o = s:option(Value, "releases_tag", translate("Keywords of Tags in Releases:"))
o.description = translate("Set the keywords of Tags in Releases of github.com in [Online Download Update].")
o.rmempty = true
o.default = amlogic_firmware_tag
o.write = function(self, key, value)
    if value == "" then
        --self.description = translate("Invalid value.")
        amlogic_firmware_tag = default_firmware_tag
    else
        --self.description = translate("Keywords of Tags in Releases:") .. value
        amlogic_firmware_tag = value
    end
end

--4.Set OpenWrt Firmware Suffix
o = s:option(Value, "firmware_suffix", translate("Suffix of OpenWrt files:"))
o.description = translate("Set the suffix of the OpenWrt in Releases of github.com in [Online Download Update].")
o.rmempty = true
o.default = amlogic_firmware_suffix
o.write = function(self, key, value)
    if value == "" then
        --self.description = translate("Invalid value.")
        amlogic_firmware_suffix = default_firmware_suffix
    else
        --self.description = translate("Suffix of OpenWrt files:") .. value
        amlogic_firmware_suffix = value
    end
end

--5.Set OpenWrt Kernel DownLoad Path
o = s:option(Value, "kernel_repo", translate("Download path of OpenWrt kernel:"))
o.description = translate("Set the download path of the kernel in the github.com repository in [Online Download Update].")
o.rmempty = true
o.default = amlogic_kernel_path
o.write = function(self, key, value)
    if value == "" then
        --self.description = translate("Invalid value.")
        amlogic_kernel_path = default_kernel_path
    else
        --self.description = translate("Download path of OpenWrt kernel:") .. value
        amlogic_kernel_path = value
    end
end

--6.Set kernel version branch
o = s:option(Value, "kernel_branch", translate("Set version branch:"))
o.description = translate("Set the version branch of the openwrt firmware and kernel selected in [Online Download Update].")
o:value("5.4", translate("5.4"))
o:value("5.10", translate("5.10"))
o:value("5.13", translate("5.13"))
o:value("5.14", translate("5.14"))
o.default = tostring(amlogic_kernel_branch)
o.rmempty = true
o.write = function(self, key, value)
    if value == "" then
        --self.description = translate("Invalid value.")
        amlogic_kernel_branch = "5.4"
    else
        --self.description = translate("Set version branch:") .. value
        amlogic_kernel_branch = value
    end
end

--7.Restore configuration
o = s:option(Flag,"restore_config",translate("Keep config update:"))
o.description = translate("Set whether to keep the current config during [Online Download Update] and [Manually Upload Update].")
o.rmempty = false
if tonumber(amlogic_firmware_config) == 0 then
    o.default = "0"
else
    o.default = "1"
end
o.write = function(self, key, value)
    if value == "1" then
        amlogic_firmware_config = "1"
    else
        amlogic_firmware_config = "0"
    end
end

--8.Write bootloader
o = s:option(Flag,"auto_write_bootloader",translate("Auto write bootloader:"))
o.description = translate("[Recommended choice] Set whether to auto write bootloader during install and update OpenWrt.")
o.rmempty = false
if tonumber(amlogic_write_bootloader) == 0 then
    o.default = "0"
else
    o.default = "1"
end
o.write = function(self, key, value)
    if value == "1" then
        amlogic_write_bootloader = "1"
    else
        amlogic_write_bootloader = "0"
    end
end

--9.Save button
o = s:option(Button, "", translate("Save Config:"))
o.template = "amlogic/other_button"
o.render = function(self, section, scope)
    self.section = true
    scope.display = ""
    self.inputtitle = translate("Save")
    self.inputstyle = "save"
    Button.render(self, section, scope)
end
o.write = function(self, section, scope)
    luci.sys.exec("uci set amlogic.config.amlogic_firmware_repo=" .. amlogic_firmware_repo .. " 2>/dev/null")
    luci.sys.exec("uci set amlogic.config.amlogic_firmware_tag=" .. amlogic_firmware_tag .. " 2>/dev/null")
    luci.sys.exec("uci set amlogic.config.amlogic_firmware_suffix=" .. amlogic_firmware_suffix .. " 2>/dev/null")
    luci.sys.exec("uci set amlogic.config.amlogic_kernel_path=" .. amlogic_kernel_path .. " 2>/dev/null")
    luci.sys.exec("uci set amlogic.config.amlogic_kernel_branch=" .. amlogic_kernel_branch .. " 2>/dev/null")
    luci.sys.exec("uci set amlogic.config.amlogic_firmware_config=" .. amlogic_firmware_config .. " 2>/dev/null")
    luci.sys.exec("uci set amlogic.config.amlogic_write_bootloader=" .. amlogic_write_bootloader .. " 2>/dev/null")
    luci.sys.exec("uci commit amlogic 2>/dev/null")
    http.redirect(DISP.build_url("admin", "system", "amlogic", "config"))
    --self.description = "amlogic_firmware_repo: " .. amlogic_firmware_repo
end


return b

