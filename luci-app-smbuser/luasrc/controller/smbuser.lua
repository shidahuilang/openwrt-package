-- Copyright 2024 sbwml <admin@cooluc.com>
-- Licensed to the public under the GPL-3.0 License.

module("luci.controller.smbuser", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/smbuser") then return end
    entry({"admin", "services", "smbuser"}, cbi("smbuser"), _("Samba4 User Management")).dependent = true
end
