module("luci.controller.taskschedule", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/taskschedule") then
		return
	end

	entry({"admin", "services", "taskschedule"}, alias("admin", "services", "taskschedule", "home"),_("任务"), 10).dependent = true  -- 任务列表
	entry({"admin", "services", "taskschedule","home"}, cbi("taskschedule/taskschedule"), _("任务"),30).leaf = true
	--entry({"admin", "services", "taskschedule", "log"}, cbi("taskschedule/log"),_("日志"), 30).leaf = true -- 日志页面
	entry({"admin", "services", "taskschedule", "log"}, call("show_log"),_("日志"), 30).leaf = true -- 日志页面
end


local function isempty(s)
  return s == nil or s == ''
end



function show_log(name)
	if isempty(name) then
  		command = "echo ''"
  	else
  		command = "/bin/cat /var/log/taskschedule-"..name..".txt"
	end
	
	log = luci.sys.exec(command)
	luci.http.prepare_content("text/html")
	luci.template.render("taskschedule/log",{log=log})
end


function act_status()
	local e = {}
	e.running = luci.sys.call("/usr/bin/pgrep -f 'qemu-system-x86_64 -name synology' >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end



