module("luci.controller.caddy", package.seeall)

function index()
	entry({"admin", "nas"}, firstchild(), _("NAS") , 45).dependent = false
	if not nixio.fs.access("/etc/config/caddy") then
		return
	end

	local page = entry({"admin", "nas", "caddy"}, alias("admin", "nas", "caddy", "basic"), _("Caddy"), 20)
	page.dependent = true
	page.acl_depends = { "luci-app-caddy" }

	entry({"admin", "nas"}, firstchild(), "NAS", 44).dependent = false
	entry({"admin", "nas", "caddy", "basic"}, cbi("caddy/caddy"), _("基本设置"), 1).leaf = true
	entry({"admin", "nas", "caddy", "log"}, cbi("caddy/caddy_log"), _("日志"), 2).leaf = true
	entry({"admin", "nas", "caddy", "caddy_status"}, call("caddy_status")).leaf = true
	entry({"admin", "nas", "caddy", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "nas", "caddy", "clear_log"}, call("clear_log")).leaf = true
        entry({"admin", "nas", "caddy", "admin_info"}, call("admin_info")).leaf = true
end

function caddy_status()
	local e={}
          local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("caddy", "caddy", "port"))
                   e.port = (port or 12311)
		    e.running=luci.sys.call("pidof caddy >/dev/null")==0
	local tagfile = io.open("/tmp/caddy_time", "r")
        if tagfile then
	local tagcontent = tagfile:read("*all")
	tagfile:close()
	if tagcontent and tagcontent ~= "" then
        os.execute("start_time=$(cat /tmp/caddy_time) && time=$(($(date +%s)-start_time)) && day=$((time/86400)) && [ $day -eq 0 ] && day='' || day=${day}天 && time=$(date -u -d @${time} +'%H小时%M分%S秒') && echo $day $time > /tmp/command_caddy 2>&1")
        local command_output_file = io.open("/tmp/command_caddy", "r")
        if command_output_file then
            e.caddysta = command_output_file:read("*all")
            command_output_file:close()
	    if e.caddysta == "" then
               e.caddysta = "unknown"
            end
        end
	end
	end

         local command2 = io.popen('test ! -z "`pidof caddy`" && (top -b -n1 | grep -E "$(pidof caddy)" 2>/dev/null | grep -v grep | awk \'{for (i=1;i<=NF;i++) {if ($i ~ /caddy/) break; else cpu=i}} END {print $cpu}\')')
                   e.caddycpu = command2:read("*all")
                   command2:close()
                   if e.caddycpu == "" then
                   e.caddycpu = "unknown"
                   end
  
         local command3 = io.popen("test ! -z `pidof caddy` && (cat /proc/$(pidof caddy | awk '{print $NF}')/status | grep -w VmRSS | awk '{printf \"%.2f MB\", $2/1024}')")
                   e.caddyram = command3:read("*all")
                   command3:close()
                   if e.caddyram == "" then
                   e.caddyram = "unknown"
                   end
  
         local command4 = io.popen("([ -s /tmp/caddy.tag ] && cat /tmp/caddy.tag ) || (echo `$(uci -q get caddy.@caddy[0].bin_dir) -v |awk '{print $1}' | sed 's/[^0-9.]*//g'` > /tmp/caddy.tag && cat /tmp/caddy.tag)")
                   e.caddytag = command4:read("*all")
                   command4:close()
                   if e.caddytag == "" then
                   e.caddytag = "unknown"
                   end
  
         local command5 = io.popen("([ -s /tmp/caddynew.tag ] && cat /tmp/caddynew.tag ) || ( curl -L -k -s --connect-timeout 3 --user-agent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36' https://api.github.com/repos/caddyserver/caddy/releases/latest | grep tag_name | sed 's/[^0-9.]*//g' >/tmp/caddynew.tag && cat /tmp/caddynew.tag )")
                   e.caddynewtag = command5:read("*all")
                   command5:close()
                   if e.caddynewtag == "" then
                   e.caddynewtag = "unknown"
                   end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
	luci.http.write(luci.sys.exec("[ -s $(uci -q get caddy.@caddy[0].log_dir) ] && cat $(uci -q get caddy.@caddy[0].log_dir)"))
end

function clear_log()
	luci.sys.call("cat /dev/null > $(uci -q get caddy.@caddy[0].log_dir)")
end

function admin_info()
	local validate = luci.sys.exec("$(uci -q get caddy.@caddy[0].bin_dir) validate --config /etc/caddy/Caddyfile --adapter caddyfile 2>&1")
	
	luci.http.prepare_content("application/json")
	luci.http.write_json({ validate = validate })
end

