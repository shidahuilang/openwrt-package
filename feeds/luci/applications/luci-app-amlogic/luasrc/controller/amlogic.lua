module("luci.controller.amlogic", package.seeall)

function index()

    page = entry({"admin", "system", "amlogic"}, alias("admin", "system", "amlogic", "info"), _("Amlogic Service"), 88)
    page.dependent = true
    entry({"admin", "system", "amlogic", "info"},cbi("amlogic/amlogic_info"),_("Amlogic Service"), 1).leaf = true
    entry({"admin", "system", "amlogic", "install"},cbi("amlogic/amlogic_install"),_("Install OpenWrt"), 2).leaf = true
    entry({"admin", "system", "amlogic", "upload"},cbi("amlogic/amlogic_upload"),_("Manually Upload Update"), 3).leaf = true
    entry({"admin", "system", "amlogic", "check"},cbi("amlogic/amlogic_check"),_("Online Download Update"), 4).leaf = true
    entry({"admin", "system", "amlogic", "backup"},cbi("amlogic/amlogic_backup"),_("Backup Firmware Config"), 5).leaf = true
    entry({"admin", "system", "amlogic", "config"},cbi("amlogic/amlogic_config"),_("Plugin Settings"), 6).leaf = true
    entry({"admin", "system", "amlogic", "log"},cbi("amlogic/amlogic_log"),_("Server Logs"), 7).leaf = true
    entry({"admin", "system", "amlogic", "check_firmware"},call("action_check_firmware"))
    entry({"admin", "system", "amlogic", "check_plugin"},call("action_check_plugin"))
    entry({"admin", "system", "amlogic", "check_kernel"},call("action_check_kernel"))
    entry({"admin", "system", "amlogic", "refresh_log"},call("action_refresh_log"))
    entry({"admin", "system", "amlogic", "del_log"},call("action_del_log"))
    entry({"admin", "system", "amlogic", "start_check_install"},call("action_start_check_install")).leaf=true
    entry({"admin", "system", "amlogic", "start_check_firmware"},call("action_start_check_firmware")).leaf=true
    entry({"admin", "system", "amlogic", "start_check_plugin"},call("action_start_check_plugin")).leaf=true
    entry({"admin", "system", "amlogic", "start_check_kernel"},call("action_start_check_kernel")).leaf=true
    entry({"admin", "system", "amlogic", "start_check_upfiles"},call("action_start_check_upfiles")).leaf=true
    entry({"admin", "system", "amlogic", "start_amlogic_install"},call("action_start_amlogic_install")).leaf=true
    entry({"admin", "system", "amlogic", "start_amlogic_update"},call("action_start_amlogic_update")).leaf=true
    entry({"admin", "system", "amlogic", "start_amlogic_kernel"},call("action_start_amlogic_kernel")).leaf=true
    entry({"admin", "system", "amlogic", "start_amlogic_plugin"},call("action_start_amlogic_plugin")).leaf=true
    entry({"admin", "system", "amlogic", "start_snapshot_delete"},call("action_start_snapshot_delete")).leaf=true
    entry({"admin", "system", "amlogic", "start_snapshot_restore"},call("action_start_snapshot_restore")).leaf=true
    entry({"admin", "system", "amlogic", "start_snapshot_list"},call("action_check_snapshot")).leaf=true
    entry({"admin", "system", "amlogic", "state"},call("action_state")).leaf=true

end

local fs = require "luci.fs"
local tmp_upload_dir = luci.sys.exec("[ -d /tmp/upload ] || mkdir -p /tmp/upload >/dev/null")
local tmp_amlogic_dir = luci.sys.exec("[ -d /tmp/amlogic ] || mkdir -p /tmp/amlogic >/dev/null")
local amlogic_firmware_config = luci.sys.exec("uci get amlogic.config.amlogic_firmware_config 2>/dev/null") or "1"
if tonumber(amlogic_firmware_config) == 0 then
    update_restore_config = "NO-RESTORE"
else
    update_restore_config = "RESTORE"
end
local amlogic_write_bootloader = luci.sys.exec("uci get amlogic.config.amlogic_write_bootloader 2>/dev/null") or "1"
if tonumber(amlogic_write_bootloader) == 0 then
    auto_write_bootloader = "NO"
else
    auto_write_bootloader = "YES"
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function action_refresh_log()
    local logfile="/tmp/amlogic/amlogic.log"
    if not fs.access(logfile) then
        luci.sys.exec("uname -a > /tmp/amlogic/amlogic.log && sync")
        luci.sys.exec("echo '' > /tmp/amlogic/amlogic_check_install.log && sync >/dev/null 2>&1")
        luci.sys.exec("echo '' > /tmp/amlogic/amlogic_check_upfiles.log && sync >/dev/null 2>&1")
        luci.sys.exec("echo '' > /tmp/amlogic/amlogic_check_plugin.log && sync >/dev/null 2>&1")
        luci.sys.exec("echo '' > /tmp/amlogic/amlogic_check_kernel.log && sync >/dev/null 2>&1")
        luci.sys.exec("echo '' > /tmp/amlogic/amlogic_check_firmware.log && sync >/dev/null 2>&1")
    end
    luci.http.prepare_content("text/plain; charset=utf-8")
    local f=io.open(logfile, "r+")
    f:seek("set")
    local a=f:read(2048000) or ""
    f:close()
    luci.http.write(a)
end

function action_del_log()
    luci.sys.exec(": > /tmp/amlogic/amlogic.log")
    luci.sys.exec(": > /tmp/amlogic/amlogic_check_install.log")
    luci.sys.exec(": > /tmp/amlogic/amlogic_check_upfiles.log")
    luci.sys.exec(": > /tmp/amlogic/amlogic_check_plugin.log")
    luci.sys.exec(": > /tmp/amlogic/amlogic_check_kernel.log")
    luci.sys.exec(": > /tmp/amlogic/amlogic_check_firmware.log")
    return
end

function start_amlogic_kernel()
    luci.sys.exec("chmod +x /usr/bin/openwrt-kernel >/dev/null 2>&1")
    local state = luci.sys.call("/usr/bin/openwrt-kernel -r > /tmp/amlogic/amlogic_check_kernel.log && sync >/dev/null 2>&1")
    return state
end

function start_amlogic_plugin()
    local ipk_state = luci.sys.call("[ -f /etc/config/amlogic ] && cp -vf /etc/config/amlogic /etc/config/amlogic_bak > /tmp/amlogic/amlogic_check_plugin.log && sync >/dev/null 2>&1")
    local ipk_state = luci.sys.call("opkg --force-reinstall install /tmp/amlogic/*.ipk > /tmp/amlogic/amlogic_check_plugin.log && sync >/dev/null 2>&1")
    local ipk_state = luci.sys.call("[ -f /etc/config/amlogic_bak ] && cp -vf /etc/config/amlogic_bak /etc/config/amlogic > /tmp/amlogic/amlogic_check_plugin.log && sync >/dev/null 2>&1")
    local ipk_state = luci.sys.call("rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/* /etc/config/amlogic_bak >/dev/null 2>&1")
    local state = luci.sys.call("echo 'Successful Update' > /tmp/amlogic/amlogic_check_plugin.log && sync >/dev/null 2>&1")
    return state
end

function start_amlogic_update()
    luci.sys.exec("chmod +x /usr/bin/openwrt-update >/dev/null 2>&1")
    local amlogic_update_sel = luci.http.formvalue("amlogic_update_sel")
    local state = luci.sys.call("/usr/bin/openwrt-update " .. amlogic_update_sel .. " " .. auto_write_bootloader .. " " .. update_restore_config .. " > /tmp/amlogic/amlogic_check_firmware.log && sync 2>/dev/null")
    return state
end

function start_amlogic_install()
    luci.sys.exec("chmod +x /usr/bin/openwrt-install >/dev/null 2>&1")
    local amlogic_install_sel = luci.http.formvalue("amlogic_install_sel")
    local res = string.split(amlogic_install_sel, "@")
    local state = luci.sys.call("/usr/bin/openwrt-install " .. auto_write_bootloader .. " " .. res[1] .. " " .. res[2] .. " > /tmp/amlogic/amlogic_check_install.log && sync 2>/dev/null")
    return state
end

function start_snapshot_delete()
    local snapshot_delete_sel = luci.http.formvalue("snapshot_delete_sel")
    local state = luci.sys.exec("btrfs subvolume delete -c /.snapshots/" .. snapshot_delete_sel .. " 2>/dev/null && sync")
    return state
end

function start_snapshot_restore()
    local snapshot_restore_sel = luci.http.formvalue("snapshot_restore_sel")
    local state = luci.sys.exec("btrfs subvolume snapshot /.snapshots/etc-" .. snapshot_restore_sel .. " /etc 2>/dev/null && sync")
    local state_nowreboot = luci.sys.exec("echo 'b' > /proc/sysrq-trigger 2>/dev/null")
    return state
end

function action_check_plugin()
    luci.sys.exec("chmod +x /usr/share/amlogic/amlogic_check_plugin.sh >/dev/null 2>&1")
    return luci.sys.call("/usr/share/amlogic/amlogic_check_plugin.sh >/dev/null 2>&1")
end

function check_plugin()
    luci.sys.exec("chmod +x /usr/share/amlogic/amlogic_check_kernel.sh >/dev/null 2>&1")
    local kernel_options = luci.http.formvalue("kernel_options")
    if kernel_options == "check" then
        local state = luci.sys.call("/usr/share/amlogic/amlogic_check_kernel.sh -check >/dev/null 2>&1")
    else
        local state = luci.sys.call("/usr/share/amlogic/amlogic_check_kernel.sh -download " .. kernel_options .. " >/dev/null 2>&1")
    end
    return state
end

function action_check_kernel()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        check_kernel_status = check_plugin();
    })
end

function action_check_firmware()
    luci.sys.exec("chmod +x /usr/share/amlogic/amlogic_check_firmware.sh >/dev/null 2>&1")
    return luci.sys.call("/usr/share/amlogic/amlogic_check_firmware.sh >/dev/null 2>&1")
end

local function start_check_upfiles()
    return luci.sys.exec("sed -n '$p' /tmp/amlogic/amlogic_check_upfiles.log 2>/dev/null")
end

local function start_check_plugin()
    return luci.sys.exec("sed -n '$p' /tmp/amlogic/amlogic_check_plugin.log 2>/dev/null")
end

local function start_check_kernel()
    return luci.sys.exec("sed -n '$p' /tmp/amlogic/amlogic_check_kernel.log 2>/dev/null")
end

local function start_check_firmware()
    return luci.sys.exec("sed -n '$p' /tmp/amlogic/amlogic_check_firmware.log 2>/dev/null")
end

local function start_check_install()
    return luci.sys.exec("sed -n '$p' /tmp/amlogic/amlogic_check_install.log 2>/dev/null")
end

function action_start_check_plugin()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        start_check_plugin = start_check_plugin();
    })
end

function action_start_check_kernel()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        start_check_kernel = start_check_kernel();
    })
end

function action_start_check_firmware()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        start_check_firmware = start_check_firmware();
    })
end

function action_start_check_install()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        start_check_install = start_check_install();
    })
end

function action_start_amlogic_install()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        rule_install_status = start_amlogic_install();
    })
end

function action_start_snapshot_delete()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        rule_delete_status = start_snapshot_delete();
    })
end

function action_start_snapshot_restore()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        rule_restore_status = start_snapshot_restore();
    })
end

function action_start_amlogic_update()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        rule_update_status = start_amlogic_update();
    })
end

function action_start_amlogic_kernel()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        rule_kernel_status = start_amlogic_kernel();
    })
end

function action_start_amlogic_plugin()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        rule_plugin_status = start_amlogic_plugin();
    })
end

function action_start_check_upfiles()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        start_check_upfiles = start_check_upfiles();
    })
end

local function current_firmware_version()
    return luci.sys.exec("ls /lib/modules/ 2>/dev/null | grep -oE '^[1-9].[0-9]{1,2}.[0-9]+'") or "Invalid value."
end

local function current_plugin_version()
    return luci.sys.exec("opkg list-installed | grep 'luci-app-amlogic' | awk '{print $3}'") or "Invalid value."
end

local function current_kernel_version()
    return luci.sys.exec("ls /lib/modules/ 2>/dev/null | grep -oE '^[1-9].[0-9]{1,2}.[0-9]+'") or "Invalid value."
end

function action_state()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        current_firmware_version = current_firmware_version(),
        current_plugin_version = current_plugin_version(),
        current_kernel_version = current_kernel_version();
    })
end

local function current_snapshot()
    return luci.sys.exec("btrfs subvolume list -rt / | awk '{print $4}' | grep .snapshots") or "Invalid value."
end

function action_check_snapshot()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        current_snapshot = current_snapshot();
    })
end

