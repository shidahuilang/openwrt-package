#!/bin/bash

require 'nixio'
require 'luci.model.uci'
require 'luci.util'
require 'luci.jsonc'
require 'luci.sys'
local api = require "luci.coredns.api"
local datatypes = require "luci.cbi.datatypes"
local appname = 'coredns'
local rule_file_path = '/usr/share/coredns/'
local debug = false
local uci = luci.model.uci.cursor()
uci:revert(appname)

rule_file_path = uci:get("coredns","global","conf_folder")
-- print(rule_file_path)

local log = function(...)
	if debug == true then
		local result = os.date("%Y-%m-%d %H:%M:%S: ") .. table.concat({...}, " ")
		print(result)
		-- luci.util.perror(result)
	else
		api.log(...)
	end
end

local function curl(url, file, ua)
	if not ua or ua == "" then
		ua = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.122 Safari/537.36"
	end
	local args = {
		"-skL", "--retry 3", "--connect-timeout 3", '--user-agent "' .. ua .. '"'
	}
	local return_code, result = api.curl_logic(url, file, args)
	return return_code
end

local execute = function()
	do
		local rule_list = {}
		local fail_list = {}
		if arg[1] then
			string.gsub(arg[1], '[^' .. "," .. ']+', function(w)
				rule_list[#rule_list + 1] = uci:get_all(appname, w) or {}
			end)
		else
			uci:foreach(appname, "coredns_rule_url", function(o)
				-- print(o)
				rule_list[#rule_list + 1] = o
			end)
		end

		for index, value in ipairs(rule_list) do
			local cfgid = value[".name"]
			local name = value.name
			local url = value.url
            local file = rule_file_path .. value.file
			-- local ua = value.user_agent
            local ua = ""

			log('正在订阅:【' .. name .. '】' .. url)
			tmpfile = "/tmp/" .. cfgid
			-- os.remove(tmpfile)
			luci.sys.exec("rm -rf " .. tmpfile)
			local raw = curl(url, tmpfile, ua)
			-- log(raw);
			log("temp file: " .. tmpfile)
			log("target file: " .. file)
			if raw == 0 then
				-- os.remove(file)
				-- os.move(tmpfile, file)
				luci.sys.exec("mv " .. tmpfile .. " " .. file)
			else
				fail_list[#fail_list + 1] = value
			end
 
		end

		if #fail_list > 0 then
			for index, value in ipairs(fail_list) do
				log(string.format('【%s】订阅失败，可能是订阅地址失效，或是网络问题，请诊断！', value.name))
			end
		end
	end
end

log("开始更新规则...")
 
xpcall(execute, function(e)
    log(e)
    log(debug.traceback())
    log('发生错误, 正在恢复服务')
end)
 
log("规则更新完毕...")


