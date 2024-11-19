module('luci.model.cbi.cqustdotnet.api.accounts', package.seeall)
local api = require('luci.model.cbi.cqustdotnet.api.api')
local const = require('luci.model.cbi.cqustdotnet.api.constants')

local uci = api.uci

---
---@class Account 校园网账号
---@field remark string 备注
---@field username string 用户名
---@field password string 密码
---@field ban string|nil 解封时间戳
---@field wrong_password boolean|nil 密码错误标记
local _ = {
  ---@type string UCI 内部名称
  ['.name'] = nil,

  ---@type string UCI 数据类型
  ['.type'] = nil,

  ---@type boolean 是否匿名 UCI 数据（无 .name）
  ['.anonymous'] = false
}

---
--- 根据排序获取首个可用账号。
---@overload fun(start_account_name:string):Account
---@overload fun():Account
---@param start_account_name string|nil 起始账号名，不包含在返回结果内
---@param end_account_name string 结束账号名，不包含在返回结果内
---@return Account|nil 可用账号，无可用账号时返回 nil
function get_first_available(start_account_name, end_account_name)
  local start_check = not start_account_name
  local index = 0
  while true do
    if not start_check then
      local datatype, account_name = uci:get(const.LUCI_NAME, '@accounts[' .. index .. ']')

      -- 没有找到起始账号
      if not datatype then
        return nil
      end

      -- 找到起始账号，开始做额外检查
      if account_name == start_account_name then
        start_check = true
      end
    else
      ---@type Account
      local account = uci:get_all(const.LUCI_NAME, '@accounts[' .. index .. ']')
      if not account then
        -- 没有指定起始账号的情况下，遍历到最后一个账号，说明没有可用账号
        if not start_account_name then
          return nil
        end

        -- 指定了起始账号的情况下，在起始账号之前的账号还没有做详细校验
        return get_first_available(nil, start_account_name)
      end

      -- 限制了结束账号
      if account['.name'] == end_account_name then
        return nil
      end

      -- 检查账号状态是否正常
      if not account.wrong_password and (not account.ban or os.difftime(account.ban, os.time()) <= 0) and not account.arrears then
        return account
      end
    end

    index = index + 1
  end
end

---
--- 获取当前在使用的账号。
---@return Account|nil 当前账号，无账号在使用时返回 nil
function current()
  local current_account_name = uci:get(const.LUCI_NAME, 'config', 'current_account')
  if not current_account_name then
    return nil
  end
  return uci:get_all(const.LUCI_NAME, current_account_name)
end
