local api = require('luci.model.cbi.cqustdotnet.api.api')
local const = require('luci.model.cbi.cqustdotnet.api.constants')

map = Map(const.LUCI_NAME)
map.pageaction = false  -- 不显示页面上的保存/应用按钮

-- 账号列表
section = map:section(TypedSection, 'accounts')
section.addremove = true  -- 添加/删除按钮
section.anonymous = true
section.sortable = true  -- 允许排序
section.template = 'cbi/tblsection'
---@language HTML
section.description = [[
您可以添加多个账号，某个账号出现问题时，会根据排序切换到其它账号。<br/>
<br/>
<span style="font-weight: normal">
  注意：账号状态为<span style="color: darkred">密码错误</span> / <span style="color: darkred">欠费</span>时，不会再尝试使用该账号，状态自然也不再刷新，您必须通过点击<code>修改</code>
  - <code>保存账号信息</code>来移除此状态。
</span>
]]
section.extedit = api.url('account', '%s')  -- 编辑按钮
section.create = function(self)
  local existed
  map.uci:foreach(const.LUCI_NAME, 'accounts', function(account)
    if not account['remark'] or not account['username'] or not account['password'] then
      existed = account['.name']
    end
  end)

  local id = existed
  if not existed then
    id = api.gen_uuid()
    TypedSection.create(self, id)
  end

  luci.http.redirect(self.extedit:format(id))
end

-- 账号备注
option = section:option(DummyValue, 'remark', '备注')
option.width = 'auto'
option.rmempty = false

-- 账号状态
option = section:option(DummyValue, 'state', '状态')
option.rawhtml = true
option.width = 'auto'
option.cfgvalue = function(_, section_id)
  local unbanned_timestamp = map.uci:get(const.LUCI_NAME, section_id, 'ban')
  if unbanned_timestamp and os.difftime(unbanned_timestamp, os.time()) > 0 then
    ---@language HTML
    return string.format([[<span style="color: red">禁封至<br/>%s</span>]], os.date('%Y-%m-%d %H:%M:%S', unbanned_timestamp))
  elseif map.uci:get_bool(const.LUCI_NAME, section_id, 'wrong_password') then
    ---@language HTML
    return [[<span style="color: darkred">密码错误</span>]]
  elseif map.uci:get_bool(const.LUCI_NAME, section_id, 'arrears') then
    ---@language HTML
    return [[<span style="color: darkred">欠费</span>]]
  else
    ---@language HTML
    return [[<span style="color: green">正常</span>]]
  end
end

-- 用户名
option = section:option(DummyValue, 'username', '用户名')
option.width = 'auto'
option.rmempty = false

section = map:section(Table, { {} }--[[ 随便给 table 一个可索引对象，让 section 不会显示 "尚无任何配置" ]])

option = section:option(Button, 'commit')
option.inputtitle = '保存更改'
option.inputstyle = 'save'
option.write = function()
  map.uci:commit(const.LUCI_NAME)
end

return map
