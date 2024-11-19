local m, section,s2

m = Map("modem", translate("Mobile Network"))
m.description = translate("Modem Server For OpenWrt")

	section = m:section(TypedSection, "ndis", translate("SIM Settings"), translate("Automatic operation upon startup \r\n ooo"))
	section.anonymous = true
	section.addremove = false
		section:tab("general", translate("General Setup"))
		section:tab("advanced", translate("Advanced Settings"))


	enable = section:taboption("general", Flag, "enabled", translate("Enable"))
	enable.rmempty  = false

	device = section:taboption("general",Value, "device", translate("Modem device"))
	device.rmempty = false
	local device_suggestions = nixio.fs.glob("/dev/cdc-wdm*")
	if device_suggestions then
		local node
		for node in device_suggestions do
			device:value(node)
		end
	end
	apn = section:taboption("general", Value, "apn", translate("APN"))
	username = section:taboption("general", Value, "username", translate("PAP/CHAP Username"))
	password = section:taboption("general", Value, "password", translate("PAP/CHAP Password"))
	password.password = true
	pincode = section:taboption("general", Value, "pincode", translate("PIN Code"))
	auth = section:taboption("general", Value, "auth", translate("Authentication Type"))
	auth.rmempty = true
	auth:value("", translate("-- Please choose --"))
	auth:value("both", "PAP/CHAP (both)")
	auth:value("pap", "PAP")
	auth:value("chap", "CHAP")
	auth:value("none", "NONE")
	tool = section:taboption("general", Value, "tool", translate("Tools"))
	tool:value("quectel-CM", "quectel-CM")
	tool.rmempty = true
	PdpType= section:taboption("general", Value, "pdptype", translate("PdpType"))
	PdpType:value("IPV4", "IPV4")
	PdpType:value("IPV6", "IPV6")
	PdpType:value("IPV4V6", "IPV4V6")
	PdpType.rmempty = true









s2 = m:section(TypedSection, "ndis", translate("Network Diagnostics"),translate("Network exception handling: \
check the network connection in a loop for 5 seconds. If the Ping IP address is not successful, After the network \
exceeds the abnormal number, restart and search the registered network again."))
s2.anonymous = true
s2.addremove = false

en = s2:option(Flag, "en", translate("Enable"))
en.rmempty = false



ipaddress= s2:option(Value, "ipaddress", translate("Ping IP address"))
ipaddress.default = "119.29.29.29"
ipaddress.rmempty=false

an = s2:option(Value, "an", translate("Abnormal number"))
an.default = "15"
an:value("3", "3")
an:value("5", "5")
an:value("10", "10")
an:value("15", "15")
an:value("20", "20")
an:value("25", "25")
an:value("30", "30")
an.rmempty=false



local apply = luci.http.formvalue("cbi.apply")
if apply then
    -- io.popen("/etc/init.d/modeminit restart")
	io.popen("/etc/init.d/modem restart")
end

return m