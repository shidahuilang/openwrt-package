module("luci.controller.admin.dynv6", package.seeall)

function index()
     entry({"admin", "network", "dynv6"}, cbi("dynv6/config"), translate("Dynv6"), 1)
end
