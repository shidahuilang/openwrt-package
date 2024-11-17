local api = require('luci.model.cbi.cqustdotnet.api.api')
local const = require('luci.model.cbi.cqustdotnet.api.constants')

map = Map(const.LUCI_NAME)
map.redirect = api.url('accounts')
map.pageaction = false

local input_section = map:section(NamedSection, arg[1])
input_section.addremove = false
input_section.dynamic = false

option = input_section:option(Value, 'remark', '账号备注')
option.rmempty = false
option.validate = function(self, value, sec)
  if value then
    local count = 0
    self.map.uci:foreach(const.LUCI_NAME, 'accounts', function(s)
      if s['.name'] ~= sec and s['remark'] == value then
        count = count + 1
      end
    end)
    if count > 0 then
      return nil, '备注已存在，请重新设置。'
    end
    return value
  end
end

option = input_section:option(Value, 'username', '用户名')
option.rows = 3
option.rmempty = false
option.validate = function(self, value, sec)
  if value then
    local count = 0
    self.map.uci:foreach(const.LUCI_NAME, 'accounts', function(s)
      if s['.name'] ~= sec and s['url'] == value then
        count = count + 1
      end
    end)
    if count > 0 then
      return nil, '相同用户名已存在，无需重复添加。'
    end
    return value
  end
end

option = input_section:option(Value, 'password', '密码')
option.password = true
option.rmempty = false

section = map:section(Table, { {} }--[[ 随便给 table 一个可索引对象，让 section 不会显示 "尚无任何配置" ]])

option = section:option(Button, 'back')
option.inputtitle = '返回列表'
option.inputstyle = 'link cbi-button-link'
option.write = function()
  map.uci:revert(const.LUCI_NAME, arg[1])
  api.http.redirect(map.redirect)
end

option = section:option(Button, 'commit')
option.inputtitle = '保存账号信息'
option.inputstyle = 'save'
option.write = function()
  if input_section.error then
    return
  end

  if map.changed then
    local changed_configs = map.uci:changes(const.LUCI_NAME)[const.LUCI_NAME][arg[1]]
    -- 更改了账号，清除禁封状态
    if changed_configs['username'] then
      map.uci:delete(const.LUCI_NAME, arg[1], 'ban')
    end

    map.uci:delete(const.LUCI_NAME, arg[1], 'wrong_password')  -- 无论是否更改了密码，都清除密码错误状态，因为用户可以重设校园网密码为本系统内填写的密码
    map.uci:commit(const.LUCI_NAME)
  end

  api.http.redirect(map.redirect)
end

return map
