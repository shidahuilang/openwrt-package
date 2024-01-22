local nixio = require "nixio"

module("luci.controller.modemconfig", package.seeall)

local utl = require "luci.util"

function index()
	entry({"admin", "modem"},  firstchild(), translate("Modem"), 45).acl_depends={"unauthenticated"}
	entry({"admin", "modem", "modemconfig"}, cbi("modem/modemconfig"), translate("Band config"), 9).acl_depends={"unauthenticated"}
end

