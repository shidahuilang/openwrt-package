module('luci.model.cbi.cqustdotnet.api.api', package.seeall)
sys = require('luci.sys')
uci = require('luci.model.uci').cursor()
dispatcher = require('luci.dispatcher')
http = require('luci.http')
const = require('luci.model.cbi.cqustdotnet.api.constants')

function url(...)
  local url = string.format('admin/services/%s', const.LUCI_NAME)
  local args = { ... }
  for _, v in pairs(args) do
    if v ~= '' then
      url = url .. '/' .. v
    end
  end
  return dispatcher.build_url(url)
end

---@type file|nil
local log_file
function log(...)
  if debug == true then
    print(...)
    return
  end

  if not log_file then
    log_file = io.open(string.format('/var/log/%s.log', const.LUCI_NAME), 'a+')
  end

  if log_file then
    log_file:write(os.date('%Y-%m-%d %H:%M:%S'), ': ')
    log_file:write(...)
    log_file:write('\n')
    log_file:flush()
  end
end

function get_log_file()
  if not log_file then
    log_file = io.open(string.format('/var/log/%s.log', const.LUCI_NAME), 'a+')
  end
  return log_file
end

function gen_uuid(keep_dash)
  local uuid = sys.exec('echo -n $(cat /proc/sys/kernel/random/uuid)')
  if keep_dash then
    return uuid
  else
    return uuid:gsub('-', '')
  end
end

function is_process_running(process_name)
  local advanced_ps = sys.exec("ps --version 2>&1 | grep -c procps-ng | tr -d '\n'")
  if advanced_ps == '1' then
    return sys.call(string.format("ps -efw | grep '%s' | grep -v grep >/dev/null", process_name)) == 0
  else
    return sys.call(string.format("ps -w | grep '%s' | grep -v grep >/dev/null", process_name)) == 0
  end
end

---
--- 删除字符串首尾的空白字符。
---
--- 该函数只适用于较为短小的字符串，字符串长度太长或者字符串全为空白字符时效率极低。
--- 查阅 http://lua-users.org/wiki/StringTrim 获取更多信息（trim5）。
---@param str string
function trim_string(str)
  return str:match('^%s*(.*%S)') or ''
end

function gc()
  if log_file then
    log_file:close()
    log_file = nil
  end
end
