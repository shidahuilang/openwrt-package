local uci  = require "luci.model.uci".cursor()
local util  = require "luci.util"
local http = require "luci.http"
local jsonc = require "luci.jsonc"
local iform = require "luci.iform"

module("luci.controller.wxedge", package.seeall)

function index()

  entry({"admin", "services", "wxedge"}, call("redirect_index"), _("网心云"), 30).dependent = true
  entry({"admin", "services", "wxedge", "pages"}, call("wxedge_index")).leaf = true
  entry({"admin", "services", "wxedge", "form"}, call("wxedge_form"))
  entry({"admin", "services", "wxedge", "submit"}, call("wxedge_submit"))
  entry({"admin", "services", "wxedge", "log"}, call("wxedge_log"))

end

local const_log_end = "XU6J03M6"
local appname = "wxedge"
local page_index = {"admin", "services", "wxedge", "pages"}

function redirect_index()
    http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function wxedge_index()
    luci.template.render("wxedge/main", {prefix=luci.dispatcher.build_url(unpack(page_index))})
end

function wxedge_form()
    local error = ""
    local scope = ""
    local success = 0

    local data = get_data()
    local result = {
        data = data,
        schema = get_schema(data)
    } 
    local response = {
            error = error,
            scope = scope,
            success = success,
            result = result,
    }
    http.prepare_content("application/json")
    http.write_json(response)
end

function get_schema(data)
  local actions
  if data.container_install then
    actions = {
      {
          name = "restart",
          text = "重启",
          type = "apply",
      },
      {
          name = "upgrade",
          text = "更新",
          type = "apply",
      },
      {
          name = "remove",
          text = "删除",
          type = "apply",
      },
    } 
  else
    actions = {
      {
          name = "install",
          text = "安装",
          type = "apply",
      },
    }
  end
  local schema = {
      actions = actions,
      containers = get_containers(data),
      description = "「网心云-容器魔方」由网心云推出的一款 docker 容器镜像软件，通过在简单安装后即可快速加入网心云共享计算生态网络，用户可根据每日的贡献量获得相应的现金收益回报。了解更多，请登录「<a href=\"https://www.onethingcloud.com/\">网心云官网</a>」",
      title = "网心云-容器魔方"
  }
  return schema
end

function get_containers(data) 
  local containers = {
      status_container(data),
      main_container(data)
  }
  return containers
end

function status_container(data)
  local status_value
  if data.container_install then
    status_value = "Wxedge 运行中"
  else
    status_value = "Wxedge 未运行"
  end
  local status_c1 = {
    labels = {
      {
        key = "状态：",
        value = status_value
      },
      {
        key = "访问：",
        value = ""
        -- value = "'<a href=\"https://' + location.host + ':6901\" target=\"_blank\">Ubuntu 桌面</a>'"
      }

    },
    description = "注意网心云会以超级权限运行！",
    title = "服务状态"
  }
  return status_c1
end

function main_container(data)
  local main_c2 = {
      properties = {
        {
          name = "instance1",
          required = true,
          title = "存储路径：",
          type = "string",
          enum = dup_to_enums(data.blocks),
          enumNames = dup_to_enums(data.blocks),
          ["ui:options"] = {
              description = "可前往「挂载磁盘」添加路径，路径选择后请勿轻易改动"
          }
        },
      },
      description = "请选择合适的存储位置进行安装，安装位置容量越大，收益越高：",
      title = "服务操作"
    }
    return main_c2
end

function get_data()
  local uci = require "luci.model.uci".cursor()
  local default_path = ""
  local blks = blocks()
  if #blks > 0 then
    default_path = blks[1] .. "/wxedge1"
  end
  local blk1 = {}
  for _, val in pairs(blks) do
    table.insert(blk1, val .. "/wxedge1")
  end

  local docker_path = util.exec("which docker")
  local container_id = util.trim(util.exec("docker ps -qf 'name="..appname.."'"))
  local container_install = (string.len(docker_path) > 0) and (string.len(container_id) > 0)

  local data = {
    port = 18888,
    instance1 = uci:get_first(appname, appname, "cache_path", default_path),
    blocks = blk1,
    container_install = container_install
  }
  return data
end

function wxedge_submit()
    local error = ""
    local scope = ""
    local success = 0
    local result
    
    local json_parse = jsonc.parse
    local content = http.content()
    local req = json_parse(content)
    if req["$apply"] == "upgrade" then
      result = install_upgrade_wxedge(req)
    elseif req["$apply"] == "install" then 
      result = install_upgrade_wxedge(req)
    elseif req["$apply"] == "restart" then 
      result = restart_wxedge(req)
    else
      result = delete_wxedge()
    end
    http.prepare_content("application/json")
    local resp = {
        error = error,
        scope = scope,
        success = success,
        result = result,
    }
    http.write_json(resp)
end

function wxedge_log()
  iform.response_log("/var/log/"..appname..".log")
end

function install_upgrade_wxedge(req)
  local cache_path = req["instance1"]

  -- save config
  local uci = require "luci.model.uci".cursor()
  uci:tset(appname, "@"..appname.."[0]", {
    cache_path = cache_path,
  })
  uci:save(appname)
  uci:commit(appname)

  -- local exec_cmd = string.format("start-stop-daemon -q -S -b -x /usr/share/wxedge/install.sh -- %s", req["$apply"])
  -- os.execute(exec_cmd)
  local exec_cmd = string.format("/usr/share/wxedge/install.sh %s", req["$apply"])
  iform.fork_exec(exec_cmd)

  local result = {
    async = true,
    exec = exec_cmd,
    async_state = req["$apply"]
  }
  return result
end

function delete_wxedge()
  local log = iform.exec_to_log("docker rm -f wxedge")
  local result = {
    async = false,
    log = log
  }
  return result
end

function restart_wxedge()
  local log = iform.exec_to_log("docker restart wxedge")
  local result = {
    async = false,
    log = log
  }
  return result
end

function blocks()
  local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
  local vals = {}
  if f then
    local ret = f:read("*all")
    f:close()
    local obj = jsonc.parse(ret)
    for _, val in pairs(obj["blockdevices"]) do
      local fsize = val["fssize"]
      if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] then
        -- fsize > 1G
        vals[#vals+1] = val["mountpoint"]
      end
    end
  end
  return vals
end

function dup_to_enums(a)
  if #a == 0 then
    return nil
  end
  local a2 = {}
  for _, val in pairs(a) do
    table.insert(a2, val)
  end
  return a2
end
