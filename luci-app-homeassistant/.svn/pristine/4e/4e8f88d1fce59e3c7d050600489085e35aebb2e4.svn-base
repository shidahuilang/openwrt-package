local util  = require "luci.util"
local http = require "luci.http"
local docker = require "luci.model.docker"
local iform = require "luci.iform"

module("luci.controller.homeassistant", package.seeall)

function index()

  entry({"admin", "services", "homeassistant"}, call("redirect_index"), _("HomeAssistant"), 30).dependent = true
  entry({"admin", "services", "homeassistant", "pages"}, call("homeassistant_index")).leaf = true
  entry({"admin", "services", "homeassistant", "form"}, call("homeassistant_form"))
  entry({"admin", "services", "homeassistant", "submit"}, call("homeassistant_submit"))
  entry({"admin", "services", "homeassistant", "log"}, call("homeassistant_log"))

end

local const_log_end = "XU6J03M6"
local appname = "homeassistant"
local page_index = {"admin", "services", "homeassistant", "pages"}

function redirect_index()
    http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function homeassistant_index()
    luci.template.render("homeassistant/main", {prefix=luci.dispatcher.build_url(unpack(page_index))})
end

function homeassistant_form()
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
  local homepage = '<a href=\"https://www.home-assistant.io/\" target=\"_blank\">https://www.home-assistant.io/</a>'
  local schema = {
    actions = actions,
    containers = get_containers(data),
    description = _("Open source home automation that puts local control and privacy first. Powered by a worldwide community of tinkerers and DIY enthusiasts.")..access..homepage,
    title = _("HomeAssistant")
  }
  return schema
end

function get_containers(data) 
    local containers = {
        status_container(data),
    }
    return containers
end

function status_container(data)
  local status_value

  if data.container_install then
    status_value = "HomeAssistant 运行中"
  else
    status_value = "HomeAssistant 未运行"
  end

  local status_c1 = {
    labels = {
      {
        key = "状态：",
        value = status_value
      },
      {
        key = "默认端口：",
        value = "8123"
      },
      {
        key = "配置路径：",
        value = "/root/homeassistant/config"
      },
      {
        key = "访问：",
        value = ""
      }

    },
    description = "HomeAssistant 安装即可，不需要任何配置，默认信息如下：",
    title = "服务状态"
  }
  return status_c1
end

function get_data() 
  local uci = require "luci.model.uci".cursor()
  local docker_path = util.exec("which docker")
  local docker_install = (string.len(docker_path) > 0)
  local container_id = util.trim(util.exec("docker ps -qf 'name="..appname.."'"))
  local container_install = (string.len(container_id) > 0)
  local data = {
    port = "8123",
    container_install = container_install
  }
  return data
end

function homeassistant_submit()
    local error = ""
    local scope = ""
    local success = 0
    local result
    
    local jsonc = require "luci.jsonc"
    local json_parse = jsonc.parse
    local content = http.content()
    local req = json_parse(content)
    if req["$apply"] == "upgrade" then
      result = install_upgrade_homeassistant(req)
    elseif req["$apply"] == "install" then 
      result = install_upgrade_homeassistant(req)
    elseif req["$apply"] == "restart" then 
      result = restart_homeassistant(req)
    else
      result = delete_homeassistant()
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

function homeassistant_log()
  iform.response_log("/var/log/"..appname..".log")
end

function install_upgrade_homeassistant(req)
  local exec_cmd = string.format("/usr/share/homeassistant/install.sh %s", req["$apply"])
  iform.fork_exec(exec_cmd)

  local result = {
    async = true,
    exec = exec_cmd,
    async_state = req["$apply"]
  }
  return result
end

function delete_homeassistant()
  local log = iform.exec_to_log("docker rm -f homeassistant")
  local result = {
    async = false,
    log = log
  }
  return result
end

function restart_homeassistant()
  local log = iform.exec_to_log("docker restart homeassistant")
  local result = {
    async = false,
    log = log
  }
  return result
end

