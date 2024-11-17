local util  = require "luci.util"
local jsonc = require "luci.jsonc"
local nixio = require "nixio"

local forcedata = {}

--forcedata.blocks = function()
--  local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
--  local vals = {}
--  if f then
--    local ret = f:read("*all")
--    f:close()
--    local obj = jsonc.parse(ret)
--    for _, val in pairs(obj["blockdevices"]) do
--      local fsize = val["fssize"]
--      if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] then
--        -- fsize > 1G
--        vals[#vals+1] = val["mountpoint"]
--      end
--    end
--  end
--  return vals
--end

--forcedata.default_image = function()
--  if string.find(nixio.uname().machine, "x86_64") then
--    return "jinshanyun/jinshan-x86_64"
--  else
--    return "jinshanyun/jinshan-arm64"
--  end
--end

local random_str = function(t)
    math.randomseed(os.time())
    local s = "0123456789"
    local value = ""

    -- 生成第一位，确保不是0
    local first_digit = math.random(1, 9)
    value = value .. tostring(first_digit)

    -- 生成后面17位
    for x = 2, t do
        local rand = math.random(#s)
        value = value .. string.sub(s, rand, rand)
    end

    return value
end


forcedata.default_uid = function()
    return random_str(18)
end

return forcedata

