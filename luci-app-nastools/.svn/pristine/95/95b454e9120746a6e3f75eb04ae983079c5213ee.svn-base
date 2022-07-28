local util  = require "luci.util"
local http = require "luci.http"
local iform = require "luci.iform"
local jsonc = require "luci.jsonc"

module("luci.controller.nastools", package.seeall)

function index()

  entry({"admin", "services", "nastools"}, call("redirect_index"), _("NasTools"), 30).dependent = true
  entry({"admin", "services", "nastools", "pages"}, call("nastools_index")).leaf = true
  entry({"admin", "services", "nastools", "form"}, call("nastools_form"))
  entry({"admin", "services", "nastools", "submit"}, call("nastools_submit"))
  entry({"admin", "services", "nastools", "log"}, call("nastools_log"))

end

local const_log_end = "XU6J03M6"
local appname = "nastools"
local page_index = {"admin", "services", "nastools", "pages"}

function redirect_index()
    http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function nastools_index()
    luci.template.render("nastools/main", {prefix=luci.dispatcher.build_url(unpack(page_index))})
end

function nastools_form()
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
  local access = _('Access homepage:')
  local homepage = '<a href=\"https://github.com/jxxghp/nas-tools\" target=\"_blank\">NasTools</a>'
  local schema = {
    actions = actions,
    containers = get_containers(data),
    description = _("NasTools is a tools for resource aggregation running in NAS.")..access.." "..homepage,
    title = _("NasTools")
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
    status_value = "NasTools 运行中"
  else
    status_value = "NasTools 未运行"
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
    description = "NasTools 的状态信息如下：",
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
          name = "auto_upgrade",
          required = true,
          title = "自动更新",
          type = "boolean"
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
    default_path = blks[1] .. "/nastools"
  end
  local blk1 = {}
  for _, val in pairs(blks) do
    table.insert(blk1, val .. "/nastools")
  end
  local docker_path = util.exec("which docker")
  local docker_install = (string.len(docker_path) > 0)
  local container_id = util.trim(util.exec("docker ps -qf 'name="..appname.."'"))
  local container_install = (string.len(container_id) > 0)
  local http_port = tonumber(uci:get_first(appname, appname, "http_port", "3003"))
  local data = {
    http_port = http_port,
    auto_upgrade = uci:get_first(appname, appname, "auto_upgrade", default_path) == "1",
    config_path = uci:get_first(appname, appname, "config_path", default_path),
    blocks = blk1,
    container_install = container_install
  }
  return data
end

function nastools_submit()
    local error = ""
    local scope = ""
    local success = 0
    local result
    
    local json_parse = jsonc.parse
    local content = http.content()
    local req = json_parse(content)
    if req["$apply"] == "upgrade" then
      result = install_upgrade_nastools(req)
    elseif req["$apply"] == "install" then 
      result = install_upgrade_nastools(req)
    elseif req["$apply"] == "restart" then 
      result = restart_nastools(req)
    else
      result = delete_nastools()
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

function nastools_log()
  iform.response_log("/var/log/"..appname..".log")
end

function install_upgrade_nastools(req)
  local http_port = req["http_port"]
  local auto_upgrade = req["auto_upgrade"]
  local auto_upgrade_num
  if auto_upgrade then
    auto_upgrade_num = 1
  else
    auto_upgrade_num = 0
  end

  -- save config
  local uci = require "luci.model.uci".cursor()
  uci:tset(appname, "@"..appname.."[0]", {
    http_port = http_port or "3003",
    auto_upgrade = auto_upgrade_num,
    config_path = req["config_path"],
  })
  uci:save(appname)
  uci:commit(appname)

  local exec_cmd = string.format("/usr/share/nastools/install.sh %s", req["$apply"])
  iform.fork_exec(exec_cmd)

  local result = {
    async = true,
    exec = exec_cmd,
    async_state = req["$apply"]
  }
  return result
end

function delete_nastools()
  local log = iform.exec_to_log("docker rm -f nastools")
  local result = {
    async = false,
    log = log
  }
  return result
end

function restart_nastools()
  local log = iform.exec_to_log("docker restart nastools")
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
