#!/usr/bin/lua

local nixio = require('nixio')
local http = require('luci.http')
local json = require('luci.jsonc')
local api = require('luci.model.cbi.cqustdotnet.api.api')
local const = require('luci.model.cbi.cqustdotnet.api.constants')
local accounts = require('luci.model.cbi.cqustdotnet.api.accounts')

local uci = api.uci

local LOCK_FILE = '/tmp/lock/' .. const.LUCI_NAME .. '_connector.lock'

local function is_file_exists(filename)
  return nixio.fs.stat(filename, 'type') == 'reg'
end

---
--- 尝试访问认证重定向主机，返回成功与否。
---
--- 参数 max_retry 为最大重试次数，不传默认为 0 不重试。
---
--- 一般情况下，不能访问认证重定向主机说明认证已经成功，少数情况是校园网故障，
--- 无需访问互联网判断。
---@overload fun():boolean
---@param max_retry number
---@return boolean
local function can_access_auth(max_retry)
  local max_try = (max_retry or 0) + 1  -- 默认不重试

  local request = nixio.socket('inet', 'stream')
  request:setopt('socket', 'sndtimeo', 1)

  for _ = 1, max_try do
    if request:connect('123.123.123.123', 80) then
      request:close()
      return true
    end
    request:shutdown()
  end
  request:close()
  return false
end

local redirect_request_http_headers
local function get_redirect_request_http_headers()
  if not redirect_request_http_headers then
    redirect_request_http_headers = table.concat({
      'GET / HTTP/1.1',
      'Host: 123.123.123.123',
      'User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1',
      'Accept: */*',
      'Accept-Language: zh-CN,zh;q=0.8',
      'Accept-Encoding: gzip, deflate',
      'Connection: keep-alive',
      'Upgrade-Insecure-Requests: 1'
    }, '\r\n')
  end
  return redirect_request_http_headers
end

---
--- 获取重定向时给定的参数，验证登录时要用。
---
--- 成功返回验证登录主机地址和参数，参数是一个 x-www-form-urlencoded 格式的字符串。失败返回 nil。
---@overload fun():string
---@return string,string | nil
local function get_auth_query_params(max_retry)
  local max_try = (max_retry or 0) + 1  -- 默认不重试
  for attempt = 1, max_try do
    local request = nixio.socket('inet', 'stream')
    request:setopt('socket', 'sndtimeo', 1)  -- 发送 1 秒超时
    if not request:connect('123.123.123.123', 80) then
      request:close()
      api.log('认证参数获取：无法连接到认证服务器，第 ', attempt, '/', max_try, ' 次尝试')
    else
      request:setopt('socket', 'rcvtimeo', 1)  -- 接收 1 秒超时
      request:send(get_redirect_request_http_headers())
      ---@type string|nil
      local response = request:recv(1024)
      request:close()
      if not response or #response == 0 then
        api.log('认证参数获取：无法从认证服务器接收响应，第 ', attempt, '/', max_try, ' 次尝试')
      else
        local auth_host = response:match('://(.-)/')
        local query_params = response:match("%?(.+)'<")
        if not auth_host or not query_params then
          api.log('认证参数获取：无法从响应中获取认证参数，第 ', attempt, '/', max_try, ' 次尝试')
        else
          return auth_host, query_params
        end
      end
    end
  end
end

local function get_auth_request_headers(host, body_length)
  return table.concat({
    'POST /eportal/InterFace.do?method=login HTTP/1.1',
    'Host: ' .. host,
    'User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1',
    'Accept: */*',
    'Accept-Language: zh-CN,zh;q=0.8',
    'Accept-Encoding: gzip, deflate',
    'Content-Type: application/x-www-form-urlencoded',
    'Content-Length: ' .. body_length,
    'Origin: http://' .. host,
    'Connection: keep-alive'
  }, '\r\n')
end

local function get_auth_request_body(username, password, query_params)
  return string.format('userId=%s&password=%s&service=&queryString=%s&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false',
      username, password, http.urlencode(http.urlencode(query_params)))
end

---
--- 尝试登录，返回成功与否。
---
--- 该函数还负责记录失败时的信息到账号内，比如账号被禁封的话，禁封到何时。
---@param account Account
---@return boolean
local function try_auth(account)
  if not account then
    return false
  end

  local auth_host, query_params = get_auth_query_params()
  if not auth_host or not query_params then
    api.log('认证：无法获取认证参数')
    return false
  end

  local auth_request_body = get_auth_request_body(account['username'], account['password'], query_params)
  local auth_request_headers = get_auth_request_headers(auth_host, #auth_request_body)
  local auth_request_content = auth_request_headers .. '\r\n\r\n' .. auth_request_body
  local request = nixio.socket('inet', 'stream')
  request:setopt('socket', 'sndtimeo', 1)  -- 发送 1 秒超时
  if not request:connect(auth_host:match('^[^:]+'), auth_host:match(':([%d]+)$') or 80) then
    request:close()
    api.log('认证：无法连接到认证服务器')
    return false
  end
  request:setopt('socket', 'rcvtimeo', 1)  -- 接收 1 秒超时
  request:send(auth_request_content)
  local response = request:recv(1024)  ---@type string
  request:close()
  if not response or #response == 0 then
    api.log('认证：无法从认证服务器接收响应')
    return false
  end

  local json_str = response:match('%b{}')
  if not json_str or #json_str <= 2 then
    local server_msg = response:match('Server:(.+)$')
    api.log('认证：无法从响应中获取有效信息，服务器响应：', server_msg)
    return false
  end

  local res, err = json.parse(json_str)
  if not res then
    api.log('认证：无法解析响应中的有效信息（', err, '）：', json_str)
    return false
  end

  -- 认证失败
  if res['result'] ~= 'success' then
    api.log('认证：失败，原因：', res['message'])

    local unparsed_response = true

    -- 检查是否被禁封
    local year, month, day, hour, minute, second = res['message']:match('([1-2]%d%d%d)%-([0-1]?%d)%-([0-3]?%d)%s(%d+):([0-5]%d):([0-5]%d)')
    if year then
      unparsed_response = false
      local unbanned_timestamp = os.time({ year = year, month = month, day = day, hour = hour, min = minute, sec = second })
      api.log('账号 ', account['username'], ' (', account['remark'], ') 被禁封至 ', year, '-', month, '-', day, ' ', hour, ':', minute, ':', second, ' (', unbanned_timestamp, ')')
      uci:set(const.LUCI_NAME, account['.name'], 'ban', unbanned_timestamp)
    end

    -- 检查密码是否错误
    if res['message']:find('密码', 1, true) then
      unparsed_response = false
      api.log('账号 ', account['username'], ' (', account['remark'], ') 密码错误')
      uci:set(const.LUCI_NAME, account['.name'], 'wrong_password', 1)
    end

    -- 检查账号是否欠费
    if res['message']:find('The subscriber status is incorrect', 1, true) then
      unparsed_response = false
      api.log('账号 ', account['username'], ' (', account['remark'], ') 已欠费')
      uci:set(const.LUCI_NAME, account['.name'], 'arrears', 1)
    end

    -- TODO: 认证响应适配
    if unparsed_response then
      local server_msg = response:match('Server:(.+)$')
      api.log('意料之外的认证响应：', api.trim_string(server_msg))
    else
      uci:commit(const.LUCI_NAME)
    end
    return false
  end

  return true
end

local function test_and_auto_switch()
  -- 无法访问认证重定向地址，说明已经认证成功，也可能是校园网故障
  if not can_access_auth() then
    return
  end

  -- 尝试一次登录当前账号，如果禁封账号需要登录来触发计时
  local current_account = accounts.current()  ---@type Account
  if current_account then
    if try_auth(current_account) then
      api.log('自动认证：重新使用账号 ', current_account['username'], ' (', current_account['remark'], ') 认证')
      return
    end
  end

  local new_account = accounts.get_first_available(current_account and current_account['.name'] or nil)
  if try_auth(new_account) then
    api.log('自动认证：切换到账号 ', new_account['username'], ' (', new_account['remark'], ')')
    uci:set(const.LUCI_NAME, 'config', 'current_account', new_account['.name'])
    uci:commit(const.LUCI_NAME)
    return
  end

  -- 自动切换账号失败，把当前账号置空，避免反复尝试登录当前账号
  if current_account then
    uci:delete(const.LUCI_NAME, 'config', 'current_account')
    uci:commit(const.LUCI_NAME)
  end
end

local function start()
  if is_file_exists(LOCK_FILE) then
    api.log('守护进程已经在运行，不重复运行')
    return
  end
  os.execute('touch ' .. LOCK_FILE)

  local enabled = uci:get(const.LUCI_NAME, 'config', 'enabled')
  if enabled ~= '1' then
    return
  end

  -- 检查间隔，一次运行只获取一次，该值变更后需要重新运行该脚本
  local interval = uci:get(const.LUCI_NAME, 'config', 'network_detection_interval') or 5

  api.log('守护进程启动，网络检测间隔 ', interval, ' 秒')

  while true do
    test_and_auto_switch()
    nixio.nanosleep(interval)
  end
end

if not arg or #arg < 1 or not arg[1] then
  start()
elseif arg[1] == 'get_available_account' then
  ---@type Account
  local account = accounts.get_first_available(arg[2], arg[3])
  if account then
    print(account['.name'])
  else
    print()
  end
elseif arg[1] == 'test' then
  print(test_and_auto_switch())
else
  start()
end
