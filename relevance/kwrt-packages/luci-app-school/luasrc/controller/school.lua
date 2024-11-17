module("luci.controller.school", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/school") then
		return
	end

    local pack
    pack = entry({"admin", "services", "school"}, alias("admin", "services", "school", "set"), _("school"), 30)
    pack.i18n = "school"
    pack.dependent = true

    entry({"admin", "services", "school", "set"}, cbi("school/school"), _("Basic Setting"), 1).leaf = true
end