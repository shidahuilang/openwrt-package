m = Map("coredns")
m.pageaction = false

m:append(Template("coredns/coredns_log"))

return m
