local fs = require "nixio.fs"
local sys  = require "luci.sys"
local http = require "luci.http"
local uci = require("luci.model.uci").cursor()

if fs.access("/usr/share/coredns/coredns") then
    coredns_version = sys.exec("/usr/share/coredns/coredns -version")
	coredns_plugins = sys.exec("/usr/share/coredns/coredns -plugins")
else
    coredns_version = translate("Unknown Version, Pleaes upload a valid CoreDNS program.")
	coredns_plugins = translate("Cannot get plugins list, please check if coredns program was uploaded correctly")
end

ful = SimpleForm("coredns", 'CoreDNS', coredns_version)
ful.reset = false
ful.submit = false

sul =ful:section(SimpleSection, translate("Upload"))
o = sul:option(FileUpload, "")
o.template = "coredns/upload"
um = sul:option(DummyValue, "", nil)
um.template = "coredns/dvalue"

local dir, fd, clash
dir = "/usr/share/coredns/"
tmp_dir="/tmp/coredns/bin/"
-- fs.mkdir(tmp_dir)
os.execute(string.format("rm -rf %s >/dev/null 2>&1", tmp_dir))
os.execute(string.format("mkdir -p %s >/dev/null 2>&1", tmp_dir))

http.setfilehandler(
	function(meta, chunk, eof)
		if not fd then
			if not meta then return end
            fd = nixio.open(tmp_dir .. meta.file, "w")
			if not fd then
				um.value = translate("Create upload file error")
				return
			end
		end
		if chunk and fd then
			fd:write(chunk)
		end
		if eof and fd then
			fd:close()
			fd = nil
            if string.lower(string.sub(meta.file, -7, -1)) == ".tar.gz" then
                os.execute(string.format("tar -C '/tmp/coredns' -xzf %s >/dev/null 2>&1", (tmp_dir .. meta.file)))
                fs.unlink(tmp_dir .. meta.file)
                os.execute(string.format("mv $(echo \"/tmp/coredns/bin/$(ls /tmp/coredns/bin/)\") '/usr/share/coredns/coredns' >/dev/null 2>&1"))
            elseif string.lower(string.sub(meta.file, -3, -1)) == ".gz" then
                os.execute(string.format("mv %s '/tmp/coredns/bin/coredns.gz' >/dev/null 2>&1", (tmp_dir .. meta.file)))
                os.execute("gzip -fd '/tmp/coredns/bin/coredns.gz' >/dev/null 2>&1")
                fs.unlink("/tmp/coredns/bin/coredns.gz")
            else
                os.execute(string.format("mv $(echo \"/tmp/coredns/bin/$(ls /tmp/coredns/bin/)\") '/usr/share/coredns/coredns' >/dev/null 2>&1"))
            end
            os.execute("chmod 4755 /usr/share/coredns/coredns >/dev/null 2>&1")
            os.execute(string.format("rm -rf %s >/dev/null 2>&1", tmp_dir))
            um.value = translate("Please refresh this page, the upload file has already been saved to") .. ' "/usr/share/coredns/coredns"'
		end
	end
)

if http.formvalue("upload") then
	local f = http.formvalue("ulfile")
	if #f <= 0 then
		um.value = translate("No Specify Upload File")
	end
end

-- ful:section(SimpleSection).template = "coredns/coredns_status"

s = ful:section(SimpleSection, translate("Plugins"))
o = s:option(TextValue, "", "")
o.default=coredns_plugins
o.readonly=true

return ful
