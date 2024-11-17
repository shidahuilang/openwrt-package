#!/usr/bin/lua

local ucic = require('uci')
local const = require('luci.model.cbi.cqustdotnet.api.constants')

local TMP_PATH = '/tmp/etc/' .. const.LUCI_NAME
local LOG_FILE = '/var/log/' .. const.LUCI_NAME .. '.log'
local APP_PATH = '/usr/share/' .. const.LUCI_NAME

local ucic_cursor = ucic.cursor
local uci = ucic_cursor()

---@type file|nil
local log_file
local function log(...)
  -- 没有打开日志文件，尝试打开
  if not log_file then
    log_file = io.open(LOG_FILE, 'a')
  end

  if log_file then
    log_file:write(os.date('%Y-%m-%d %H:%M:%S'), ': ')
    log_file:write(...)
    log_file:write('\n')
    log_file:flush()
  end
end

local function clean_log_if_too_long()
  if log_file then
    log_file:close()
  end

  local writable_log_file = io.open(LOG_FILE, 'rw')
  if writable_log_file then
    local lines_count = 0
    for _ in writable_log_file:lines() do
      lines_count = lines_count + 1

      -- 日志大于 1000 行，清空日志
      if lines_count > 1000 then
        writable_log_file:write('日志文件过长，清空')
        break
      end
    end
    writable_log_file:close()
  end
end

---
--- 将 table 转换为 vararg（也就是 ...）。
---@overload fun(tab:table):any
local function unpack(tab, index)
  index = index or 1
  if tab[index] then
    return tab[index], unpack(tab, index + 1)
  end
end

---@type string|nil
local app_enabled

---
--- 获取当前 LuCI App 启用状态，也就是总开关是否打开。
---
--- 参数 reload 默认为 false，当 reload 为 true 时，会重新获取状态，
--- 否则只会获取一次状态，其后的调用都会直接返回已经获取到的状态。
---@overload fun(): boolean
---@param reload boolean
---@return boolean
local function is_app_enabled(reload)
  if reload or app_enabled == nil then
    app_enabled = uci:get(const.LUCI_NAME, 'config', 'enabled') or '0'
  end
  return app_enabled == '1'
end

---
--- 清除与当前 LuCI App 相关的定时任务。
local function clean_crontab()
  local crontab_file = io.open('/etc/crontabs/root', 'rw')
  local crontab = {}
  for cron in crontab_file:lines('*L') do
    if not cron:find(const.LUCI_NAME) then
      table.insert(crontab, cron)
    end
  end
  crontab_file:write(table.concat(crontab))
  crontab_file:close()
end

local function start_crontab()
  -- TODO: 当前没有定时任务
  --clean_crontab()
  if not is_app_enabled() then
    -- TODO: 当前没有定时任务
    --os.execute('/etc/init.d/cron restart')
    return
  end

  os.execute(APP_PATH .. '/connector.lua >/dev/null 2>&1 &')

  -- TODO: 当前没有定时任务
  --os.execute('/etc/init.d/cron restart')
end

local function stop_crontab()
  clean_crontab()
  os.execute('/etc/init.d/cron restart')
end

local function start()
  start_crontab()
  log('进程启动完毕')
end

local function boot()
  if is_app_enabled() then
    start()
  end
end

local function stop()
  clean_log_if_too_long()

  ---@language Shell Script
  os.execute(string.format("pgrep -af '%s/' | awk '! /app\\.lua/{print $1}' | xargs kill -9 >/dev/null 2>&1", const.LUCI_NAME))
  stop_crontab()
  os.remove('/tmp/lock/' .. const.LUCI_NAME .. '_connector.lock')
  log('清空并关闭相关程序和缓存完成')

  os.exit(0)
end

-- 没有运行参数，退出
if type(arg) ~= "table" then
  return
end

local action = arg[1]
if action == 'start' then
  start()
elseif action == 'stop' then
  stop()
elseif action == 'boot' then
  boot()
elseif action == 'log' then
  -- 删掉第一个参数，也就是 action
  local args = {}
  for i = 2, #arg do
    table.insert(args, arg[i])
  end
  log(unpack(args))
end
