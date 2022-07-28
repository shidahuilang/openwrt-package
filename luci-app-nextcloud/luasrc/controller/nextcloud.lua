local util  = require "luci.util"
local http = require "luci.http"
local docker = require "luci.model.docker"
local iform = require "luci.iform"

module("luci.controller.nextcloud", package.seeall)

function index()

  entry({"admin", "services", "nextcloud"}, call("redirect_index"), _("NextCloud"), 30).dependent = true
  entry({"admin", "services", "nextcloud", "pages"}, call("nextcloud_index")).leaf = true
  entry({"admin", "services", "nextcloud", "form"}, call("nextcloud_form"))
  entry({"admin", "services", "nextcloud", "submit"}, call("nextcloud_submit"))
  entry({"admin", "services", "nextcloud", "log"}, call("nextcloud_log"))

end

local const_log_end = "XU6J03M6"
local appname = "nextcloud"
local page_index = {"admin", "services", "nextcloud", "pages"}

function redirect_index()
    http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function nextcloud_index()
    luci.template.render("nextcloud/main", {prefix=luci.dispatcher.build_url(unpack(page_index))})
end

function nextcloud_form()
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
  local homepage = '<a href=\"https://nextcloud.com/\" target=\"_blank\">https://nextcloud.com/</a>'
  local schema = {
    actions = actions,
    containers = get_containers(data),
    description = _("A safe home for all your data. Access & share your files, calendars, contacts, mail & more from any device, on your terms.")..access..homepage,
    title = _("NextCloud")
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
    status_value = "NextCloud 运行中"
  else
    status_value = "NextCloud 未运行"
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
    description = "NextCloud 的状态信息如下：",
    title = "服务状态"
  }
  return status_c1
end

function main_container(data)
    local main_c2 = {
        properties = {
          {
            name = "port",
            required = true,
            title = "端口",
            type = "string"
          },
        },
        description = "请设置端口：",
        title = "服务操作"
      }
      return main_c2
end

function get_data() 
  local uci = require "luci.model.uci".cursor()
  local docker_path = util.exec("which docker")
  local docker_install = (string.len(docker_path) > 0)
  local container_id = util.trim(util.exec("docker ps -qf 'name="..appname.."'"))
  local container_install = (string.len(container_id) > 0)
  local port = tonumber(uci:get_first(appname, appname, "port", "8082"))
  local data = {
    port = port,
    container_install = container_install
  }
  return data
end

function nextcloud_submit()
    local error = ""
    local scope = ""
    local success = 0
    local result
    
    local jsonc = require "luci.jsonc"
    local json_parse = jsonc.parse
    local content = http.content()
    local req = json_parse(content)
    if req["$apply"] == "upgrade" then
      result = install_upgrade_nextcloud(req)
    elseif req["$apply"] == "install" then 
      result = install_upgrade_nextcloud(req)
    elseif req["$apply"] == "restart" then 
      result = restart_nextcloud(req)
    else
      result = delete_nextcloud()
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

function nextcloud_log()
  iform.response_log("/var/log/"..appname..".log")
end

function install_upgrade_nextcloud(req)
  local port = req["port"]

  -- save config
  local uci = require "luci.model.uci".cursor()
  uci:tset(appname, "@"..appname.."[0]", {
    port = port or "8082",
  })
  uci:save(appname)
  uci:commit(appname)

  local exec_cmd = string.format("/usr/share/nextcloud/install.sh %s", req["$apply"])
  iform.fork_exec(exec_cmd)

  local result = {
    async = true,
    exec = exec_cmd,
    async_state = req["$apply"]
  }
  return result
end

function delete_nextcloud()
  local log = iform.exec_to_log("docker rm -f nextcloud")
  local result = {
    async = false,
    log = log
  }
  return result
end

function restart_nextcloud()
  local log = iform.exec_to_log("docker restart nextcloud")
  local result = {
    async = false,
    log = log
  }
  return result
end

