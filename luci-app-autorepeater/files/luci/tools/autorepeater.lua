-- Copyright 2014 Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
-- Licensed to the public under the Apache License 2.0.

module("luci.tools.autorepeater", package.seeall)

local NX   = require "nixio"
local NXFS = require "nixio.fs"
local OPKG = require "luci.model.ipkg"
local UCI  = require "luci.model.uci"
local SYS  = require "luci.sys"
local UTIL = require "luci.util"

local translate, translatef = luci.i18n.translate, luci.i18n.translatef
local function tr(...)
	return tostring(translate(...))
end
function opt_enabled(s, t, n, ...)
        if t == luci.cbi.Button then
                local o = s:option(t, "__enabled")
                function o.render(self, section)
                        if self.map:get(section, n) ~= "1" then
                                self.title      = tr("Enabled")
                                self.inputtitle = tr("Disable")
                                self.inputstyle = "reset"
                        else
                                self.title      = tr("Disabled")
                                self.inputtitle = tr("Enable")
                                self.inputstyle = "apply"
                        end
                        t.render(self, section)
                end
                function o.write(self, section, value)
                        if self.map:get(section, n) ~= "1" then
                                self.map:set(section, n, "1")
                        else
                                self.map:del(section, n)
                        end
                end
                return o
        else
                local o = s:option(t, n, ...)
                o.default = "0"
                return o
        end
end

-- function to calculate seconds from given interval and unit
function calc_seconds(interval, unit)
	if not tonumber(interval) then
		return nil
	elseif unit == "days" then
		return (tonumber(interval) * 86400)	-- 60 sec * 60 min * 24 h
	elseif unit == "hours" then
		return (tonumber(interval) * 3600)	-- 60 sec * 60 min
	elseif unit == "minutes" then
		return (tonumber(interval) * 60)	-- 60 sec
	elseif unit == "seconds" then
		return tonumber(interval)
	else
		return nil
	end
end

-- check if Wget with SSL support or cURL installed
function check_ssl()
	if (SYS.call([[ grep -i "\+ssl" /usr/bin/wget >/dev/null 2>&1 ]]) == 0) then
		return true
	else
		return NXFS.access("/usr/bin/curl")
	end
end

-- check if Wget with SSL or cURL with proxy support installed
function check_proxy()
	-- we prefere GNU Wget for communication
	if (SYS.call([[ grep -i "\+ssl" /usr/bin/wget >/dev/null 2>&1 ]]) == 0) then
		return true

	-- if not installed cURL must support proxy
	elseif NXFS.access("/usr/bin/curl") then
		return (SYS.call([[ grep -i all_proxy /usr/lib/libcurl.so* >/dev/null 2>&1 ]]) == 0)

	-- only BusyBox Wget is installed
	else
		return NXFS.access("/usr/bin/wget")
	end
end

function has_bin(name)
	return SYS.call("command -v %s >/dev/null" %{name}) == 0
end

-- convert epoch date to given format
function epoch2date(epoch, format)
	if not format or #format < 2 then
		local uci = UCI.cursor()
		format    = uci:get("autorepeater", "global", "date_format") or "%F %R"
		uci:unload("autorepeater")
	end
	format = format:gsub("%%n", "<br />")	-- replace newline
	format = format:gsub("%%t", "    ")	-- replace tab
	return os.date(format, epoch)
end

-- read lastupdate from [section].update file
function get_lastconn(section)
	local uci     = UCI.cursor()
	local run_dir = uci:get("autorepeater", "global", "run_dir") or "/var/run/autorepeater"
	local etime   = tonumber(NXFS.readfile("%s/%s.update" % { run_dir, section } ) or 0 )
	uci:unload("autorepeater")
	return etime
end

-- read PID from run file and verify if still running
function get_pid(section)
	local uci     = UCI.cursor()
	local run_dir = uci:get("autorepeater", "global", "run_dir") or "/var/run/autorepeater"
	local pid     = tonumber(NXFS.readfile("%s/%s.pid" % { run_dir, section } ) or 0 )
	if pid > 0 and not NX.kill(pid, 0) then
		pid = 0
	end
	uci:unload("autorepeater")
	return pid
end

-- read version information for given package if installed
function ipkg_ver_installed(pkg)
	local version = nil
	local control = io.open("/usr/lib/opkg/info/%s.control" % pkg, "r")
	if control then
		local ln
		repeat
			ln = control:read("*l")
			if ln and ln:match("^Version: ") then
				version = ln:gsub("^Version: ", "")
				break
			end
		until not ln
		control:close()
	end
	return version
end

-- replacement of build-in read of UCI option
-- modified AbstractValue.cfgvalue(self, section) from cbi.lua
-- needed to read from other option then current value definition
function read_value(self, section, option)
	local value
	if self.tag_error[section] then
		value = self:formvalue(section)
	else
		value = self.map:get(section, option)
	end

	if not value then
		return nil
	elseif not self.cast or self.cast == type(value) then
		return value
	elseif self.cast == "string" then
		if type(value) == "table" then
			return value[1]
		end
	elseif self.cast == "table" then
		return { value }
	end
end

-- replacement of build-in Flag.parse of cbi.lua
-- modified to mark section as changed if value changes
-- current parse did not do this, but it is done AbstaractValue.parse()
function flag_parse(self, section)
	local fexists = self.map:formvalue(
		luci.cbi.FEXIST_PREFIX .. self.config .. "." .. section .. "." .. self.option)

	if fexists then
		local fvalue = self:formvalue(section) and self.enabled or self.disabled
		local cvalue = self:cfgvalue(section)
		if fvalue ~= self.default or (not self.optional and not self.rmempty) then
			self:write(section, fvalue)
		else
			self:remove(section)
		end
		if (fvalue ~= cvalue) then self.section.changed = true end
	else
		self:remove(section)
		self.section.changed = true
	end
end

-----------------------------------------------------------------------------
-- copied from https://svn.nmap.org/nmap/nselib/url.lua
-- @author Diego Nehab
-- @author Eddie Bell <ejlbell@gmail.com>
--[[
    URI parsing, composition and relative URL resolution
    LuaSocket toolkit.
    Author: Diego Nehab
    RCS ID: $Id: url.lua,v 1.37 2005/11/22 08:33:29 diego Exp $
    parse_query and build_query added For nmap (Eddie Bell <ejlbell@gmail.com>)
]]--
---
-- Parses a URL and returns a table with all its parts according to RFC 2396.
--
-- The following grammar describes the names given to the URL parts.
-- <code>
-- <url> ::= <scheme>://<authority>/<path>;<params>?<query>#<fragment>
-- <authority> ::= <userinfo>@<host>:<port>
-- <userinfo> ::= <user>[:<password>]
-- <path> :: = {<segment>/}<segment>
-- </code>
--
-- The leading <code>/</code> in <code>/<path></code> is considered part of
-- <code><path></code>.
-- @param url URL of request.
-- @param default Table with default values for each field.
-- @return A table with the following fields, where RFC naming conventions have
--   been preserved:
--     <code>scheme</code>, <code>authority</code>, <code>userinfo</code>,
--     <code>user</code>, <code>password</code>, <code>host</code>,
--     <code>port</code>, <code>path</code>, <code>params</code>,
--     <code>query</code>, and <code>fragment</code>.
-----------------------------------------------------------------------------
function parse_url(url)	--, default)
	-- initialize default parameters
	local parsed = {}
--	for i,v in base.pairs(default or parsed) do
--		parsed[i] = v
--	end

	-- remove whitespace
--	url = string.gsub(url, "%s", "")
	-- get fragment
	url = string.gsub(url, "#(.*)$",
		function(f)
			parsed.fragment = f
			return ""
		end)
	-- get scheme. Lower-case according to RFC 3986 section 3.1.
	url = string.gsub(url, "^([%w][%w%+%-%.]*)%:",
		function(s)
			parsed.scheme = string.lower(s);
			return ""
		end)
	-- get authority
	url = string.gsub(url, "^//([^/]*)",
		function(n)
			parsed.authority = n
			return ""
		end)
	-- get query stringing
	url = string.gsub(url, "%?(.*)",
		function(q)
			parsed.query = q
			return ""
		end)
	-- get params
	url = string.gsub(url, "%;(.*)",
		function(p)
			parsed.params = p
			return ""
		end)
	-- path is whatever was left
	parsed.path = url

	local authority = parsed.authority
	if not authority then
		return parsed
	end
	authority = string.gsub(authority,"^([^@]*)@",
		function(u)
			parsed.userinfo = u;
			return ""
		end)
	authority = string.gsub(authority, ":([0-9]*)$",
		function(p)
			if p ~= "" then
				parsed.port = p
			end;
			return ""
		end)
	if authority ~= "" then
		parsed.host = authority
	end

	local userinfo = parsed.userinfo
	if not userinfo then
		return parsed
	end
	userinfo = string.gsub(userinfo, ":([^:]*)$",
		function(p)
			parsed.password = p;
			return ""
		end)
	parsed.user = userinfo
	return parsed
end
