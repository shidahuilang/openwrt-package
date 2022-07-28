local util  = require "luci.util"
local http = require "luci.http"
local iform = require "luci.iform"
local jsonc = require "luci.jsonc"

module("luci.controller.heimdall", package.seeall)

function index()

  entry({"admin", "services", "heimdall"}, call("redirect_index"), _("Heimdall"), 30).dependent = true
  entry({"admin", "services", "heimdall", "pages"}, call("heimdall_index")).leaf = true
  entry({"admin", "services", "heimdall", "form"}, call("heimdall_form"))
  entry({"admin", "services", "heimdall", "submit"}, call("heimdall_submit"))
  entry({"admin", "services", "heimdall", "log"}, call("heimdall_log"))

end

local const_log_end = "XU6J03M6"
local appname = "heimdall"
local page_index = {"admin", "services", "heimdall", "pages"}

function redirect_index()
    http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function heimdall_index()
    luci.template.render("heimdall/main", {prefix=luci.dispatcher.build_url(unpack(page_index))})
end

function heimdall_form()
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
  local _ = luci.i18n.translate
  local access = _('access homepage: ')
  local homepage = '<a href=\"https://github.com/linuxserver/Heimdall\" target=\"_blank\">Heimdall</a>'
  local schema = {
    actions = actions,
    containers = get_containers(data),
    description = _("Heimdall is an elegant solution to organise all your web applications.")..access..homepage,
    title = _("Heimdall")
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
    status_value = "Heimdall 运行中"
  else
    status_value = "Heimdall 未运行"
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
      }

    },
    description = "Heimdall 的状态信息如下：",
    title = "服务状态"
  }
  return status_c1
end

function main_container(data)
  local main_c2 = {
      properties = {
        {
          name = "http_port",
          required = true,
          title = "HTTP 端口",
          type = "string"
        },
        {
          name = "https_port",
          required = true,
          title = "HTTPS 端口",
          type = "string"
        },
        {
          name = "config_path",
          required = true,
          title = "配置路径：",
          type = "string",
          enum = dup_to_enums(data.blocks),
          enumNames = dup_to_enums(data.blocks)
        },
      },
      description = "请选择合适的配置路径进行安装：",
      title = "服务操作"
    }
    return main_c2
end

function get_data() 
  local uci = require "luci.model.uci".cursor()
  local default_path = ""
  local blks = blocks()
  if #blks > 0 then
    default_path = blks[1] .. "/heimdall"
  end
  local blk1 = {}
  for _, val in pairs(blks) do
    table.insert(blk1, val .. "/heimdall")
  end
  local docker_path = util.exec("which docker")
  local docker_install = (string.len(docker_path) > 0)
  local container_id = util.trim(util.exec("docker ps -qf 'name="..appname.."'"))
  local container_install = (string.len(container_id) > 0)
  local http_port = tonumber(uci:get_first(appname, appname, "http_port", "8088"))
  local https_port = tonumber(uci:get_first(appname, appname, "https_port", "8089"))
  local data = {
    http_port = http_port,
    https_port = https_port,
    lang = uci:get_first(appname, appname, "lang", "en"),
    config_path = uci:get_first(appname, appname, "config_path", default_path),
    blocks = blk1,
    container_install = container_install
  }
  return data
end

function heimdall_submit()
    local error = ""
    local scope = ""
    local success = 0
    local result
    
    local json_parse = jsonc.parse
    local content = http.content()
    local req = json_parse(content)
    if req["$apply"] == "upgrade" then
      result = install_upgrade_heimdall(req)
    elseif req["$apply"] == "install" then 
      result = install_upgrade_heimdall(req)
    elseif req["$apply"] == "restart" then 
      result = restart_heimdall(req)
    else
      result = delete_heimdall()
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

function heimdall_log()
  iform.response_log("/var/log/"..appname..".log")
end

function install_upgrade_heimdall(req)
  local http_port = req["http_port"]
  local https_port = req["https_port"]

  -- save config
  local uci = require "luci.model.uci".cursor()
  uci:tset(appname, "@"..appname.."[0]", {
    http_port = http_port or "8088",
    https_port = https_port or "8089",
    lang = req["lang"],
    config_path = req["config_path"],
  })
  uci:save(appname)
  uci:commit(appname)

  local exec_cmd = string.format("/usr/share/heimdall/install.sh %s", req["$apply"])
  iform.fork_exec(exec_cmd)

  local result = {
    async = true,
    exec = exec_cmd,
    async_state = req["$apply"]
  }
  return result
end

function delete_heimdall()
  local log = iform.exec_to_log("docker rm -f heimdall")
  local result = {
    async = false,
    log = log
  }
  return result
end

function restart_heimdall()
  local log = iform.exec_to_log("docker restart heimdall")
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
