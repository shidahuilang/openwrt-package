local m, s

m = Map("openai")
m.title = translate("ChatGPT")
m.description = translate("ChatGPT is an AI assistant that is exclusively yours.")

m:section(SimpleSection).template  = "openai/openai_status"

s = m:section(TypedSection, "openai")
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enabled"))
o.rmempty = false

o = s:option(Value, "port", translate("Port"))
o.datatype = "and(port,min(1))"
o.rmempty = false
o.default = 5052

o = s:option(Flag, "log", translate("Enable Logs"))
o.default = 0
o.rmempty = false
o.default = true

o = s:option(Flag, "allow_wan", translate("Allow Access From WAN"))
o.rmempty = false
o.default = true

o = s:option(Flag, "disable_gpt4", translate("Disable GPT-4 Model"))
o.rmempty = false
o.default = false

o = s:option(Value, "base_url", translate("OpenAI API URL"), translate("OpenAI API URL, you can customize a reverse proxy endpoint that is suitable for the current network."))
o.default = "https://api.openai.com"
o:value("https://api.openai.com", translate("https://api.openai.com (official)"))
o:value("https://chatgpt1.nextweb.fun/api/proxy", translate("https://chatgpt1.nextweb.fun/api/proxy (anti-proxy)"))

o = s:option(Value, "openai_api_key", translate("OpenAI API Keys"), translate("Please Enter your OpenAI API Keys.") .. '<br />' .. [[<a href="https://platform.openai.com/account/api-keys" target="_blank">]] .. translate("Get OpenAI API Keys") .. [[</a>]])
o.datatype = "string"
o.password = true

o = s:option(Value, "user_code", translate("Access Password"))
o.password = true

return m
