local e=require"luci.ip"
m=Map("qos-emong",translate("Emong's QOS"),translate("Easy to use qos, <font color=\"red\">do not open with other qos at the same time.</font>"))
s=m:section(TypedSection,"qos-emong",translate("QOS Goble Setting"))
s.anonymous=true
s.addremove=false
o=s:option(Flag,"enable",translate("QOS Enable"))
o.default=false
o.rmempty=false
o=s:option(Value,"down",translate("Total Download Speed(Kbps)"))
o.default=102400
o.rmempty=false
o=s:option(Value,"up",translate("Total Upload Speed(Kbps)"))
o.default=4096
o.rmempty=false
s=m:section(TypedSection,"ip-limit",translate("Single IP or IP Segment Speed Limit"),
translate("For example: 192.168.1.100 192.168.1.100/25, Please do not use 192.168.1.100-192.168.1.150, unit Kbps,1Mbps=1024Kbps"))
s.template="cbi/tblsection"
s.sortable=false
s.anonymous=true
s.addremove=true
o=s:option(Flag,"enable",translate("Enable"))
o.width="30%"
o.rmempty=false
o=s:option(Value,"ip",translate("IP Address"))
o.width="20%"
o.datatype="ip4addr"
luci.ip.neighbors({family = 4}, function(neighbor)
if neighbor.reachable then
o:value(neighbor.dest:string(), "%s" %{neighbor.dest:string()})
end
end)
o=s:option(Value,"downc",translate("Maximum Download Speed"))
o.default=1500
o.rmempty=false
o=s:option(Value,"downr",translate("Guarantee Download Speed"))
o.default=500
o.rmempty=false
o=s:option(Value,"upc",translate("Maximum Upload Speed"))
o.default=500
o.rmempty=false
o=s:option(Value,"upr",translate("Guarantee Upload Speed"))
o.default=200
o.rmempty=false
s=m:section(TypedSection,"connlmt",translate("Number of Connections"),
translate("Allows the maximum number of connections for tcp and udp"))
s.template="cbi/tblsection"
s.sortable=false
s.anonymous=true
s.addremove=true
o=s:option(Flag,"enable",translate("Enable"))
o.width="30%"
o.rmempty=false
o=s:option(Value,"ip",translate("IP Address"))
o.width="20%"
o.datatype="ip4addr"
luci.ip.neighbors({family = 4}, function(neighbor)
if neighbor.reachable then
o:value(neighbor.dest:string(), "%s" %{neighbor.dest:string()})
end
end)
o=s:option(Value,"tcp",translate("TCP Maximum Number Connections"))
o.default=100
o.rmempty=false
o=s:option(Value,"udp",translate("UDP Maximum Number Connections"))
o.default=100
o.rmempty=false
s=m:section(TypedSection,"port_first",translate("Port Priority"),
translate("Priority port will not be marked into the queue, You can put the application of high delay requirements here."))
s.template="cbi/tblsection"
s.sortable=true
s.anonymous=true
s.addremove=true
o=s:option(Flag,"enable",translate("Enable"))
o.width="30%"
o.rmempty=false
o=s:option(ListValue,"proto",translate("Protocol"))
o:value("tcp",translate("TCP"))
o:value("udp",translate("UDP"))
o.rmempty=false
o=s:option(Value,"port",translate("Port"))
o.default="23,80,25000:26000"
o.rmempty=false
return m
