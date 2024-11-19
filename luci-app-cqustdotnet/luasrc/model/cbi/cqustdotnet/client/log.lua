local const = require('luci.model.cbi.cqustdotnet.api.constants')

local form = SimpleForm(const.LUCI_NAME)
form.reset = false
form.submit = false
form:append(Template(const.LUCI_NAME .. '/log/log'))

return form
