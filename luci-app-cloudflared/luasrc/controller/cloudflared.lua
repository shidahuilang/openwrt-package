module("luci.controller.cloudflared",package.seeall)

function index()
  if not nixio.fs.access("/etc/config/cloudflared")then
return
end

entry({"admin","vpn"}, firstchild(), "VPN", 49).dependent = false

entry({"admin", "vpn", "cloudflared"},firstchild(), _("Cloudflared")).dependent = false

entry({"admin", "vpn", "cloudflared", "general"},cbi("cloudflared/settings"), _("配置"), 1)
entry({"admin", "vpn", "cloudflared", "log"},form("cloudflared/info"), _("日志"), 2)

entry({"admin","vpn","cloudflared","status"},call("act_status"))
end

function act_status()
local e={}
  e.running=luci.sys.call("pidof cloudflared0 >/dev/null")==0

local tagfile = io.open("/tmp/cloudflared_time", "r")
        if tagfile then
	local tagcontent = tagfile:read("*all")
	tagfile:close()
	if tagcontent and tagcontent ~= "" then
        os.execute("start_time=$(cat /tmp/cloudflared_time) && time=$(($(date +%s)-start_time)) && day=$((time/86400)) && [ $day -eq 0 ] && day='' || day=${day}天 && time=$(date -u -d @${time} +'%H小时%M分%S秒') && echo $day $time > /tmp/command_cloudflared 2>&1")
        local command_output_file = io.open("/tmp/command_cloudflared", "r")
        if command_output_file then
            e.cfsta = command_output_file:read("*all")
            command_output_file:close()
	          if e.cfsta == "" then
               e.cfsta = "unknown"
            end
        end
	end
	end
  
  local command2 = io.popen('test ! -z "`pidof cloudflared0`" && (top -b -n1 | grep -E "$(pidof cloudflared0)" 2>/dev/null | grep -v grep | awk \'{for (i=1;i<=NF;i++) {if ($i ~ /cloudflared0/) break; else cpu=i}} END {print $cpu}\')')
  e.cfcpu = command2:read("*all")
  command2:close()
  if e.cfcpu == "" then
  e.cfcpu = "Unknown"
  end
  
  local command3 = io.popen("test ! -z `pidof cloudflared0` && (cat /proc/$(pidof cloudflared0 | awk '{print $NF}')/status | grep -w VmRSS | awk '{printf \"%.2f MB\", $2/1024}')")
  e.cfram = command3:read("*all")
  command3:close()
  if e.cfram == "" then
  e.cfram = "Unknown"
  end
  
  local command4 = io.popen("([ -s /tmp/cloudflared.tag ] && cat /tmp/cloudflared.tag ) || (echo `/usr/bin/cloudflared version | awk '{print $3}'` > /tmp/cloudflared.tag && cat /tmp/cloudflared.tag)")
  e.cftag = command4:read("*all")
  command4:close()
  if e.cftag == "" then
  e.cftag = "Unknown"
  end
  
  local command5 = io.popen("([ -s /tmp/cloudflarednew.tag ] && cat /tmp/cloudflarednew.tag ) || ( curl -L -k -s --connect-timeout 3 --user-agent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36' https://api.github.com/repos/cloudflare/cloudflared/releases/latest | grep tag_name | sed 's/[^0-9.]*//g' >/tmp/cloudflarednew.tag && cat /tmp/cloudflarednew.tag )")
  e.cfnewtag = command5:read("*all")
  command5:close()
  if e.cfnewtag == "" then
  e.cfnewtag = "Unknown"
  end
  
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end
