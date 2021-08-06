-- Licensed to the public under the GNU General Public License v3.
local m, s, o
local vssr = 'vssr'
local json = require 'luci.jsonc'

local uci = luci.model.uci.cursor()
local server_count = 0
local server_table = {}
uci:foreach(
    'vssr',
    'servers',
    function(s)
        server_count = server_count + 1
        s['name'] = s['.name']
        if(s.alias == nil) then
            s.alias = "未命名节点"
        end
        table.insert(server_table, s)
    end
)

local name = ''
uci:foreach(
    'vssr',
    'global',
    function(s)
        name = s['.name']
    end
)
function my_sort(a,b)
    if(a.alias ~= nil and b.alias ~= nil) then
        return  a.alias < b.alias
    end
end
table.sort(server_table, my_sort)
m = Map(vssr)

m:section(SimpleSection).template = 'vssr/status_top'

-- [[ Servers List ]]--
s = m:section(TypedSection, 'servers')
s.anonymous = true
s.addremove = true
s.sortable = false

s.des = server_count
s.current = uci:get('vssr', name, 'global_server')
s.serverTable = server_table
s.servers = json.stringify(server_table)
s.template = 'vssr/tblsection'
s.extedit = luci.dispatcher.build_url('admin/services/vssr/servers/%s')
function s.create(...)
    local sid = TypedSection.create(...)
    if sid then
        luci.http.redirect(s.extedit % sid)
        return
    end
end

m:section(SimpleSection).template = 'vssr/status_bottom'

return m
