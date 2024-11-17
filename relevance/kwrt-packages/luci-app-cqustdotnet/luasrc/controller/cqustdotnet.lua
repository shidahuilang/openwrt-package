module('luci.controller.cqustdotnet', package.seeall)

function index()
  -- upvalues 在此函数中是 nil，使用的话需要 require
  local app_name = require('luci.model.cbi.cqustdotnet.api.constants').LUCI_NAME

  entry({ 'admin', 'services', app_name }).dependent = true
  entry({ 'admin', 'services', app_name, 'reset_config' }, call('reset_config')).leaf = true
  if not nixio.fs.access('/etc/config/cqustdotnet') then
    return
  end
  e = entry({ 'admin', 'services', app_name }, alias('admin', 'services', app_name, 'index'), _('CQUST.net'), -10)
  e.dependent = true
  e.acl_depends = { 'luci-app-cqustdotnet' }

  -- Client
  entry({ 'admin', 'services', app_name, 'index' }, cbi(app_name .. '/client/global'), _('主页'), 1).dependent = true
  entry({ 'admin', 'services', app_name, 'accounts' }, cbi(app_name .. '/client/accounts'), _('账号'), 2).dependent = true
  entry({ 'admin', 'services', app_name, 'account' }, cbi(app_name .. '/client/account')).leaf = true
  entry({ 'admin', 'services', app_name, 'log' }, form(app_name .. '/client/log'), _('日志'), 999).leaf = true

  -- API
  entry({ 'admin', 'services', app_name, 'status' }, call('status')).leaf = true
  entry({ 'admin', 'services', app_name, 'get_log' }, call('get_log')).leaf = true
  entry({ 'admin', 'services', app_name, 'clear_log' }, call('clear_log')).leaf = true
  entry({ 'admin', 'services', app_name, 'fetch_log' }, call('fetch_log')).leaf = true
end

local api = require('luci.model.cbi.cqustdotnet.api.api')
local accounts = require('luci.model.cbi.cqustdotnet.api.accounts')
local const = require('luci.model.cbi.cqustdotnet.api.constants')

function reset_config()
  ---@language Shell Script
  luci.sys.call([[
    /etc/init.d/cqustdotnet stop
    [ -f /usr/share/cqustdotnet/0_default_config ] && cp -f /usr/share/cqustdotnet/0_default_config /etc/config/cqustdotnet
  ]])
  luci.http.redirect(api.url())
end

function status()
  local status = {
    connector = api.is_process_running(const.LUCI_NAME .. '/connector.lua')
  }

  ---@type Account|nil
  local current_account = accounts.current()
  if current_account then
    status.account = string.format('%s (%s)', current_account.username, current_account.remark)
  end

  luci.http.prepare_content('application/json')
  luci.http.write_json(status)
end

function get_log()
  luci.http.write(luci.sys.exec("[ -f '/var/log/cqustdotnet.log' ] && cat /var/log/cqustdotnet.log"))
end

function fetch_log()
  local log_file = api.get_log_file()  ---@type file|nil

  -- 日志不存在，返回 404 Not Found
  if not log_file then
    luci.http.status(404, 'Not Found')
    luci.http.close()
    return
  end

  local after = tonumber(luci.http.formvalue('after'))
  local before = tonumber(luci.http.formvalue('before'))
  local limit = 1024  -- 一次最多返回 1KB 的日志

  luci.http.prepare_content('application/json')
  local file_size = log_file:seek('end')
  if after == before or (after and before) then
    -- after 和 before 都为空时，返回最新日志。
    -- after 和 before 相等时，视为空参数，返回最新的日志。
    -- after 和 before 都存在时，属于错误参数，按未传入参数处理。
    if file_size > limit then
      log_file:seek('end', -limit)
    else
      log_file:seek('set')
    end
    luci.http.write_json({
      cursor = file_size,
      fragment = (log_file:read(limit))
    })
  elseif after then
    -- after 不为空，before 为空，返回 after 之后的日志
    log_file:seek('set', after)
    luci.http.write_json({
      cursor = file_size - after > limit and after + limit or file_size,
      fragment = log_file:read(limit)
    })
  else
    -- before 不为空，after 为空，返回 before 之前的日志
    log_file:seek('set', before <= limit and 0 or before - limit)
    luci.http.write_json({ fragment = log_file:read(before < limit and limit - before or limit) })
  end
end

function clear_log()
  luci.sys.call("echo '' > /var/log/cqustdotnet.log")
end
