'use strict';
'require uci';
'require form';
'require network';
'require fs';
'require ui';

network.registerPatternVirtual(/^tinc-.+$/);
function getHosts(section_id) {
    return fs.list('/etc/tinc/' + section_id + '/hosts').then(function (lines) {
        return lines.map(function (file) {
            if (file.type === 'file') {
                return file.name;
            }
        });
    }).then(L.bind(function (names) {
        this.names = names;
        return this.super('load', section_id);
    }, this));
}
return network.registerProtocol('tinc', {
    IPAddr: form.Value.extend({
        validate: function (section_id, value) {
            var str = this.formvalue(section_id);
            if (str.length > 0) {
                var m = str.match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,3}$/);
                if (!m) {
                    return _('Expecting: valid IPv4 CIDR');
                }
            }
            return true;
        }
    }),
    IP6Addr: form.Value.extend({
        validate: function (section_id, value) {
            var str = this.formvalue(section_id);
            if (str.length > 0) {
                var m = str.match(/^([\da-fA-F]{1,4}:){6}((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^::([\da-fA-F]{1,4}:){0,4}((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:):([\da-fA-F]{1,4}:){0,3}((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){2}:([\da-fA-F]{1,4}:){0,2}((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){3}:([\da-fA-F]{1,4}:){0,1}((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){4}:((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){7}[\da-fA-F]{1,4}(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^:((:[\da-fA-F]{1,4}){1,6}|:)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^[\da-fA-F]{1,4}:((:[\da-fA-F]{1,4}){1,5}|:)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){2}((:[\da-fA-F]{1,4}){1,4}|:)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){3}((:[\da-fA-F]{1,4}){1,3}|:)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){4}((:[\da-fA-F]{1,4}){1,2}|:)(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){5}:([\da-fA-F]{1,4})?(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$|^([\da-fA-F]{1,4}:){6}:(\/([1-9]?\d|(1([0-1]\d|2[0-8]))))?$/);
                if (!m) {
                    return _('Expecting: valid IPv6 CIDR');
                }
            }
            return true;
        }
    }),
    Name: form.Value.extend({
        validate: function (section_id, value) {
            var str = this.formvalue(section_id);
            if (str.length > 16 || !str.match(/^[a-zA-Z0-9_\-.]+$/)) {
                return _('valid node name');
            }
            return true;
        }
    }),
    BindToAddress: form.Value.extend({
        validate: function (section_id, value) {
            var str = this.formvalue(section_id);
            if (str.length > 0 && !str.match(/^\*\ \d+$/)) {
                return _('Format: <address> [<port>]');
            }
            return true;
        }
    }),
    DropDownList: form.ListValue.extend({
        renderWidget: function (section_id, option_index, cfgvalue) {
            var values = L.toArray((cfgvalue != null) ? cfgvalue : this.default);
            var widget = new ui.Dropdown(values, this.choices, {
                id: this.cbid(section_id),
                sort: this.sort,
                multiple: this.multiple,
                optional: this.optional,
                select_placeholder: E('em', _(this.placeholder || 'unspecified')),
                optional: this.optional || this.rmempty,
            });
            return widget.render();
        }
    }),
    ConnectTo: form.ListValue.extend({
        load: getHosts,
        filter: function (section_id, value) {
            return true;
        },
        renderWidget: function (section_id, option_index, cfgvalue) {
            var values = L.toArray((cfgvalue != null) ? cfgvalue : this.default)
                , choices = {};
            for (var i = 0; i < this.names.length; i++) {
                choices[this.names[i]] = E('span', {
                    'class': 'zonebadge',
                }, E('label', _(this.names[i])));
            }
            var widget = new ui.Dropdown(values, choices, {
                id: this.cbid(section_id),
                sort: true,
                multiple: true,
                select_placeholder: E('em', _(this.placeholder || 'unspecified')),
            });
            return widget.render();
        }
    }),
    Option: form.DynamicList.extend({
        validate: function (section_id, value) {
            var val = this.formvalue(section_id),
                i;
            for (i = 0; i < val.length; i++) {
                if (val[i].length > 0 && !val[i].match(/^[a-zA-Z0-9_\-]+=[a-zA-Z0-9_\-]+$/)) {
                    return _('Expecting: valid option');
                }
            }
            return true;
        }
    }),
    Route: form.DynamicList.extend({
        validate: function (section_id, value) {
            var val = this.formvalue(section_id),
                i;
            return true;
        }
    }),
    getI18n: function () {
        return _('TincVPN');
    },
    getIfname: function () {
        return this._ubus('l3_device') || 'tinc-%s'.format(this.sid);
    },
    getOpkgPackage: function () {
        return 'tinc';
    },
    containsDevice: function (ifname) {
        return (network.getIfnameOf(ifname) == this.getIfname());
    },
    renderFormOptions: function (s) {
        var dev = this.getL3Device() || this.getDevice(),
            o;
        o = s.taboption('general', this.IPAddr, 'ipaddr', _('IPv4 Address'));
        o.datatype = 'cidr';
        o = s.taboption('general', this.IP6Addr, 'ip6addr', _('IPv6 Address'));
        o.datatype = 'cidr6';
        o.optional = true
        o = s.taboption('general', this.Name, 'name', _('Name'));
        s.taboption('general', this.BindToAddress, 'bindtoaddr', _('BindToAddress'));
        s.taboption('general', this.ConnectTo, 'connect', _('ConnectTo'));
        o = s.taboption('general', this.DropDownList, 'mode', _('Mode'));
        o.choices = { 'router': 'router', 'switch': 'switch', 'hub': 'hub' };
        o = s.taboption('general', this.DropDownList, 'priority', _('ProcessPriority'));
        o.choices = { 'low': 'low', 'normal': 'normal', 'high': 'high' };
        o = s.taboption('general', this.DropDownList, 'strict_subnets', _('StrictSubnets'));
        o.choices = { 'yes': 'yes', 'no': 'no' };
        s.taboption('general', this.Option, 'option', _('Extra option'));
        o = s.taboption('general', form.DynamicList, 'subnet', _('Subnet'));
        o.datatype = 'cidr';
        s.taboption('general', this.Route, 'route', _('Route'));
        o = s.taboption('general', form.Value, 'mtu', _('Override MTU'));
        o.placeholder = dev ? (dev.getMTU() || '1400') : '1400';
        o.datatype = 'range(68, 9200)';
    }
});

