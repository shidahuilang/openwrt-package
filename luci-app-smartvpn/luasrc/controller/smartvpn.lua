-- SmartVPN menu entry point registration
-- stub lua controller for 19.07 backward compatibility

module("luci.controller.smartvpn", package.seeall)

function index()
	entry({"admin", "network", "smartvpn"}, firstchild(), _("SmartVPN"), 60)
	entry({"admin", "network", "smartvpn", "overview"}, view("smartvpn/overview"), _("Overview"), 10)
	entry({"admin", "network", "smartvpn", "mainland"}, view("smartvpn/mainland"), _("Mainland hosts"), 20)
	entry({"admin", "network", "smartvpn", "hongkong"}, view("smartvpn/hongkong"), _("Hongkong hosts"), 30)
	entry({"admin", "network", "smartvpn", "oversea"}, view("smartvpn/oversea"), _("Oversea hosts"), 40)
 end
 