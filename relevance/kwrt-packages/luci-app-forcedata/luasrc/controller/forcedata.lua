
module("luci.controller.forcedata", package.seeall)

function index()
  entry({"admin", "services", "forcedata"}, alias("admin", "services", "forcedata", "config"), _("Forcedata"), 30).dependent = true
  entry({"admin", "services", "forcedata", "config"}, cbi("forcedata"))
end
