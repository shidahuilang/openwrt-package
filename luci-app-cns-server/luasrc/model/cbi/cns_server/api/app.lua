#!/usr/bin/lua
local action = arg[1]
local sys = require 'luci.sys'
local jsonc = require "luci.jsonc"
local ucic = require"luci.model.uci".cursor()

local CONFIG = "cns_server"
local CONFIG_PATH = "/var/etc/" .. CONFIG
local LOG_PATH = "/var/log/" .. CONFIG
local LOG_APP_FILE = LOG_PATH .. "/app.log"
local BIN_PATH = "/var/bin/"
local BIN_PATH_FILE = BIN_PATH .. CONFIG
local nixio = require "nixio"
local util = require "luci.util"

local function log(...)
	local f, err = io.open(LOG_APP_FILE, "a")
    if f and err == nil then
        local str = os.date("%Y-%m-%d %H:%M:%S: ") .. table.concat({...}, " ")
        f:write(str .. "\n")
        f:close()
    end
end

local function cmd(cmd)
    sys.call(cmd)
end

local function gen_include()
    cmd(string.format("echo '#!/bin/sh' > /var/etc/%s.include", CONFIG))
    local function extract_rules(a)
        local result = "*" .. a
        result = result .. "\n" .. sys.exec('iptables-save -t ' .. a .. ' | grep "CNS-SERVER" | sed -e "s/^-A \\(INPUT\\)/-I \\1 1/"')
        result = result .. "COMMIT"
        return result
    end
    local f, err = io.open("/var/etc/" .. CONFIG .. ".include", "a")
    if f and err == nil then
        f:write('iptables-save -c | grep -v "CNS-SERVER" | iptables-restore -c' .. "\n")
        f:write('iptables-restore -n <<-EOT' .. "\n")
        f:write(extract_rules("filter") .. "\n")
        f:write("EOT" .. "\n")
        f:close()
    end
end


local function start()
    local enabled = tonumber(ucic:get(CONFIG, "@global[0]", "enable") or 0)
    if enabled == nil or enabled == 0 then
        return
    end
    cmd(string.format("mkdir -p %s %s", CONFIG_PATH, LOG_PATH))
    cmd(string.format("touch %s", LOG_APP_FILE))
    cmd("iptables -N CNS-SERVER")
    cmd("iptables -I INPUT -j CNS-SERVER")
    ucic:foreach(CONFIG, "user", function(user)
        local id = user[".name"]
        local enable = user.enable
        if enable and tonumber(enable) == 1 then
            local remarks = user.remarks
            local ports = table.concat(user.port, "|")
            if nixio.fs.access("/usr/bin/cns") and not nixio.fs.access(BIN_PATH_FILE) then
                cmd(string.format("mkdir -p %s", BIN_PATH))
                cmd(string.format("cp -a /usr/bin/cns %s", BIN_PATH_FILE))
            end
            local bin = BIN_PATH_FILE
            local config = {}
            local config_file = CONFIG_PATH .. "/" .. id .. ".json"

            config = require("luci.model.cbi.cns_server.api.gen_config").gen_config(user)
            bin = bin .. " -json=" .. config_file
            if next(config) then
                local f, err = io.open(config_file, "w")
                if f and err == nil then
                    f:write(jsonc.stringify(config, 1))
                    f:close()
                end
                log(string.format("%s %s 生成配置文件并运行 - %s", remarks, ports, config_file))
            end

            if bin then
                cmd(bin .. ">/dev/null 2>&1 &")
            end

            local bind_local = user.bind_local or 0
            if bind_local and tonumber(bind_local) ~= 1 then
                for _,port in pairs(user.port) do
                    cmd(string.format('iptables -A CNS-SERVER -p tcp --dport %s -m comment --comment "%s" -j ACCEPT', port, remarks))
                    cmd(string.format('iptables -A CNS-SERVER -p udp --dport %s -m comment --comment "%s" -j ACCEPT', port, remarks))
                end
            end
        end
    end)
    gen_include()
end

local function stop()
    cmd(string.format("ps -w | grep -v 'grep' | grep '%s/' | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1 &", CONFIG_PATH))
    cmd("iptables -D INPUT -j CNS-SERVER 2>/dev/null")
    cmd("iptables -F CNS-SERVER 2>/dev/null")
    cmd("iptables -X CNS-SERVER 2>/dev/null")
    cmd(string.format("rm -rf %s %s /var/etc/%s.include", CONFIG_PATH, LOG_APP_FILE, CONFIG))
end

if action then
    if action == "start" then
        start()
	elseif action == "stop" then
        stop()
	end
end

