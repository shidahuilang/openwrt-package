local netmod = luci.model.network
local p = "netkeeper"
local proto = netmod:register_protocol(p)

function proto.get_i18n(self)
		return luci.i18n.translate("Netkeeper")
end

function proto.ifname(self)
	return p .. "-" .. self.sid
end

function proto.opkg_package(self)
		return "netkeeper"
end

function proto.is_installed(self)
		return (nixio.fs.glob("/usr/lib/pppd/*/rp-pppoe.so")() ~= nil)
end

function proto.is_floating(self)
	return false
end

function proto.is_virtual(self)
	return true
end

function proto.get_interfaces(self)
	if self:is_floating() then
		return nil
	else
		return netmod.protocol.get_interfaces(self)
	end
end

function proto.contains_interface(self, ifc)
	if self:is_floating() then
		return (netmod:ifnameof(ifc) == self:ifname())
	else
		return netmod.protocol.contains_interface(self, ifc)
	end
end

netmod:register_pattern_virtual("^%s%%-%%w" % p)
