module("luci.model.cbi.cns_server/api/cns", package.seeall)
local fs = require "nixio.fs"
local sys = require "luci.sys"
local uci = require"luci.model.uci".cursor()
local util = require "luci.util"
local i18n = require "luci.i18n"
local ipkg = require "luci.model.ipkg"

local appname = "cns_server"
local cns_api ="https://api.github.com/repos/mmmdbybyd/CNS/releases/latest"
local wget = "/usr/bin/wget"
local wget_args = {"--no-check-certificate", "--quiet", "--timeout=100", "--tries=3"}
local command_timeout = 300

local LEDE_BOARD = nil
local DISTRIB_TARGET = nil
local is_armv7 = false

local function _unpack(t, i)
    i = i or 1
    if t[i] ~= nil then return t[i], _unpack(t, i + 1) end
end

local function exec(cmd, args, writer, timeout)
    local os = require "os"
    local nixio = require "nixio"

    local fdi, fdo = nixio.pipe()
    local pid = nixio.fork()

    if pid > 0 then
        fdo:close()

        if writer or timeout then
            local starttime = os.time()
            while true do
                if timeout and os.difftime(os.time(), starttime) >= timeout then
                    nixio.kill(pid, nixio.const.SIGTERM)
                    return 1
                end

                if writer then
                    local buffer = fdi:read(2048)
                    if buffer and #buffer > 0 then
                        writer(buffer)
                    end
                end

                local wpid, stat, code = nixio.waitpid(pid, "nohang")

                if wpid and stat == "exited" then return code end

                if not writer and timeout then nixio.nanosleep(1) end
            end
        else
            local wpid, stat, code = nixio.waitpid(pid)
            return wpid and stat == "exited" and code
        end
    elseif pid == 0 then
        nixio.dup(fdo, nixio.stdout)
        fdi:close()
        fdo:close()
        nixio.exece(cmd, args, nil)
        nixio.stdout:close()
        os.exit(1)
    end
end

local function compare_versions(ver1, comp, ver2)
    local table = table

    local av1 = util.split(ver1, "[%.%-]", nil, true)
    local av2 = util.split(ver2, "[%.%-]", nil, true)

    local max = table.getn(av1)
    local n2 = table.getn(av2)
    if (max < n2) then max = n2 end

    for i = 1, max, 1 do
        local s1 = av1[i] or ""
        local s2 = av2[i] or ""

        if comp == "~=" and (s1 ~= s2) then return true end
        if (comp == "<" or comp == "<=") and (s1 < s2) then return true end
        if (comp == ">" or comp == ">=") and (s1 > s2) then return true end
        if (s1 ~= s2) then return false end
    end

    return not (comp == "<" or comp == ">")
end

-- 获取当前版本 结果：版本号/不存在
-- 获取远程版本
-- 对比版本 对比线上版本跟本地版本/判断远程跟本地版本谁比较新 判断本地版本是否不存在

-- 获取当前架构
local function auto_get_arch()
    local arch = nixio.uname().machine or ""
    if fs.access("/usr/lib/os-release") then
        LEDE_BOARD = sys.exec("echo -n `grep 'LEDE_BOARD' /usr/lib/os-release | awk -F '[\\042\\047]' '{print $2}'`")
    end
    if fs.access("/etc/openwrt_release") then
        DISTRIB_TARGET = sys.exec("echo -n `grep 'DISTRIB_TARGET' /etc/openwrt_release | awk -F '[\\042\\047]' '{print $2}'`")
    end

    if arch == "mips" then
        if LEDE_BOARD and LEDE_BOARD ~= "" then
            if string.match(LEDE_BOARD, "ramips") == "ramips" then
                arch = "ramips"
            else
                arch = sys.exec("echo '" .. LEDE_BOARD .. "' | grep -oE 'ramips|ar71xx'")
            end
        elseif DISTRIB_TARGET and DISTRIB_TARGET ~= "" then
            if string.match(DISTRIB_TARGET, "ramips") == "ramips" then
                arch = "ramips"
            else
                arch = sys.exec("echo '" .. DISTRIB_TARGET .. "' | grep -oE 'ramips|ar71xx'")
            end
        end
    end

    return util.trim(arch)
end

-- 转换架构TAG
local function get_file_info(arch)
    local file_tree = ""
    local sub_version = ""

    if arch == "x86_64" then
        file_tree = "amd64"
    elseif arch == "aarch64" then
        file_tree = "arm64"
    elseif arch == "ramips" then
        file_tree = "mipsle"
    elseif arch == "ar71xx" then
        file_tree = "mips"
    elseif arch:match("^i[%d]86$") then
        file_tree = "386"
    elseif arch:match("^armv[5-8]") then
        file_tree = "arm"
        sub_version = arch:match("[5-8]")
        if LEDE_BOARD and string.match(LEDE_BOARD, "bcm53xx") == "bcm53xx" then
            sub_version = "5"
        elseif DISTRIB_TARGET and string.match(DISTRIB_TARGET, "bcm53xx") ==
            "bcm53xx" then
            sub_version = "5"
        end
        sub_version = "5"
        if sub_version == "7" then is_armv7 = true end
    end

    return file_tree, sub_version
end

local function get_api_json(url)
    local jsonc = require "luci.jsonc"

    local output = {}
    -- exec(wget, { "-O-", url, _unpack(wget_args) },
    --	function(chunk) output[#output + 1] = chunk end)
    -- local json_content = util.trim(table.concat(output))

    local json_content = sys.exec(wget .. " --no-check-certificate --timeout=10 -t 1 -O- " .. url)

    if json_content == "" then return {} end

    return jsonc.parse(json_content) or {}
end

function get_cns_file_path() return "/usr/bin" end

function get_cns_version()
    if get_cns_file_path() and get_cns_file_path() ~= "" then
        if fs.access(get_cns_file_path() .. "/cns") then
            return sys.exec("echo -n `" .. get_cns_file_path() .. "/cns -help 2>&1 | sed -n 3p | awk '{print $4}')$'\n'" .. "`")
        end
    end
    return ""
end

function to_check(arch)
    if not arch or arch == "" then arch = auto_get_arch() end

    local file_tree, sub_version = get_file_info(arch)
    if file_tree == "" then
        return {
            code = 1,
            error = i18n.translate("Can't determine ARCH, or ARCH not supported.")
        }
    end

    local json = get_api_json(cns_api)

    if json.tag_name == nil then
        return {
            code = 1,
            error = i18n.translate("Get remote version info failed.")
        }
    end

    local remote_version = json.tag_name:match("[^v]+")
    local needs_update = compare_versions(get_cns_version(), "<",remote_version)
    local html_url, download_url

    if needs_update then
        html_url = json.html_url
        for _, v in ipairs(json.assets) do
            if v.name and v.name:match("linux%_" .. file_tree) then
                download_url = v.browser_download_url
                break
            end
        end
    end

    if needs_update and not download_url then
        return {
            code = 1,
            now_version = get_cns_version(),
            version = remote_version,
            html_url = html_url,
            error = i18n.translate("New version found, but failed to get new version download url.")
        }
    end

    return {
        code = 0,
        update = needs_update,
        now_version = get_cns_version(),
        version = remote_version,
        url = {html = html_url, download = download_url}
    }
end

function to_download(url)
    if not url or url == "" then
        return {code = 1, error = i18n.translate("Download url is required.")}
    end

    sys.call("/bin/rm -f /tmp/cns_download.*")

    local tmp_file = util.trim(util.exec("mktemp -u -t cns_download.XXXXXX"))

    local result = exec(wget, {"-O", tmp_file, url, _unpack(wget_args)}, nil, command_timeout) == 0

    if not result then
        exec("/bin/rm", {"-f", tmp_file})
        return {
            code = 1,
            error = i18n.translatef("File download failed or timed out: %s", url)
        }
    end

    return {code = 0, file = tmp_file}
end


function to_move(file)
    if not file or file == "" then
        sys.call("/bin/rm -rf /tmp/cns_download*")
        return {code = 1, error = i18n.translate("Client file is required.")}
    end

    local client_file_path = get_cns_file_path()

    local client_file = client_file_path .."/cns"

    -- sys.call("mkdir -p " .. client_file)

    local result = nil
        result = exec("/bin/mv", {"-f", file , client_file}, nil, command_timeout) == 0
    if not result or not fs.access(client_file) then
        sys.call("/bin/rm -rf ".. file)
        return {
            code = 1,
            error = i18n.translatef("Can't move new file to: %s", client_file)
        }
    end

    exec("/bin/chmod", {"-R", "755", client_file})

    sys.call("/bin/rm -rf " .. file)

    return {code = 0}
end


