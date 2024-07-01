module("luci.controller.zerotier",package.seeall)

function index()
  if not nixio.fs.access("/etc/config/zerotier") then
    return
  end
  entry({"admin", "vpn"}, firstchild(), "VPN", 45).dependent = false
  entry({"admin", "vpn", "zerotier"}, alias("admin", "vpn", "zerotier", "settings"), _("ZeroTier"), 99)
  entry({"admin", "vpn", "zerotier", "settings"},cbi("zerotier/settings"), _("Base Setting"), 1)
  entry({"admin", "vpn", "zerotier", "interface"},template("zerotier/interface"), _("Interface Info"), 2)
  entry({"admin", "vpn", "zerotier", "status"},call("act_status"))
  entry({"admin", "vpn", "zerotier", "info"},call("act_info"))
end

function act_status()
  local e={}
  e.running=luci.sys.call("pgrep /usr/bin/zerotier-one >/dev/null") == 0
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end

function act_info()
  local raw_json = luci.sys.exec("ifconfig | grep -A 8 'zt' | awk -F' ' 'BEGIN {printf \"{\\\"interface\\\":\\\"\"} /Link encap/ {printf $1 \"\\\"\"} /HWaddr/ {printf \",\\\"HWaddr\\\":\\\"\" $5 \"\\\"\"} /inet addr:/ {gsub(/addr:/, \"\", $2); printf \",\\\"inet_addr\\\":\\\"\" $2 \"\\\"\"} /inet6 addr/ {printf \",\\\"inet6_addr\\\":\\\"\" $3 \"\\\"\"} /MTU:/ {gsub(/MTU:/, \"\", $5); printf \",\\\"MTU\\\":\" $5} /RX bytes:/ {gsub(/RX bytes:/, \"\", $2); gsub(/\\(|\\)/, \"\"); printf \",\\\"RX_bytes\\\":\\\"\" $3 \" \" $4 \"\\\"\"} /TX bytes:/ {gsub(/TX bytes:/, \"\", $2); gsub(/\\(|\\)/, \"\"); printf \",\\\"TX_bytes\\\":\\\"\" $7 \" \" $8 \"\\\"\"} /UP/ {printf \",\\\"status_UP\\\":true\"} END {print \"}\"}'")
  luci.http.prepare_content("application/json")
  luci.http.write(raw_json)
end
