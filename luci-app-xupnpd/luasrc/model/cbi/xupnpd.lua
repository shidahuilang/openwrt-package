m=Map("xupnpd")
m.title=translate("XUNPD IPTV Config")
m.description=translate("XUNPD for IPTV DLNA Service")
m:section(SimpleSection).template="xupnpd/xupnpd_status"
s=m:section(TypedSection,"xupnpd")
s.addremove=false
s.anonymous=true
s:tab("basic",translate("Basic Setting"))
enable=s:taboption("basic",Flag,"enabled",translate("Enable"))
enable.rmempty=false
autoactivate=s:taboption("basic",Flag,"autoactivate",translate("Broadcast for LAN Only"))
autoactivate.rmempty=false
autoactivate.description=translate("<a style=color:blue; href=\"../../../../iptv.m3u\" target=\"_blank\" />"..translate("HTTP M3U List Download").."</a>")
s:tab("config",translate("IPTV M3U List"))
config=s:taboption("config",Value,"config",translate("Replace 192.168.0.1 to your router IP"))
config.template="cbi/tvalue"
config.rows=13
config.wrap="off"
function config.cfgvalue(e,e)
return nixio.fs.readfile("/usr/share/xupnpd/playlists/iptv.m3u")
end
function config.write(t,t,e)
e=e:gsub("\r\n?","\n")
nixio.fs.writefile("/usr/share/xupnpd/playlists/iptv.m3u",e)
end
return m
