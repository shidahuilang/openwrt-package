'use strict';
'require baseclass'
'require validation';

function validateHostname(sid, s) {
	if (s == null || s == '')
		return true;

	if (s.length > 256)
		return _('Expecting: %s').format(_('valid hostname'));

	var labels = s.replace(/^\.+|\.$/g, '').split(/\./);

	for (var i = 0; i < labels.length; i++)
		if (!labels[i].match(/^[a-z0-9_](?:[a-z0-9-]{0,61}[a-z0-9])?$/i))
			return _('Expecting: %s').format(_('valid hostname'));

	return true;
}

function validateAddressList(sid, s) {
	if (s == null || s == '')
		return true;

	var m = s.match(/^\/(.+)\/$/),
	    names = m ? m[1].split(/\//) : [ s ];

	for (var i = 0; i < names.length; i++) {
		var res = validateHostname(sid, names[i]);

		if (res !== true)
			return res;
	}

	return true;
}

return baseclass.extend({
	validateStingWhitespace: function(sec, s) {
		if (s == null || s == '')
			return true;

	    if (/\s/.test(s))
            return _('Expecting: %s').format(_('string without white space'));
        else
            return true;
	},

	validateIPUnixSocket: function(sec, s) {
		if (s == null || s == '')
			return true;

		if (/^([\\/][a-z0-9\s\-_\@\-\^!#$%&]*)+(\.[a-z][a-z0-9]+)?$/i.test(s) || validation.parseIPv4(s) || validation.parseIPv6(s))
			return true;
		else
			return _('Expecting: %s').format(_('valid IP address or unix socket'));
	},

	validateDirectory: function(sec, s) {
		if (s == null || s == '')
			return true;

		if (/^([\\/][a-z0-9\s\-_\@\-\^!#$%&]*)+(\.[a-z][a-z0-9]+)?$/i.test(s))
			return true;
		else
			return _('Expecting: %s').format(_('valid directory path'));
	},

	validateServerSpec: function(sid, s) {
		if (s == null || s == '')
			return true;

		var m = s.match(/^(?:\/(.+)\/)?(.*)$/);
		if (!m)
			return _('Expecting: %s').format(_('valid hostname'));

		var res = validateAddressList(sid, m[1]);
		if (res !== true)
			return res;

		if (m[2] == '' || m[2] == '#')
			return true;

		// ipaddr%scopeid#srvport@source@interface#srcport

		m = m[2].match(/^([0-9a-f:.]+)(?:%[^#@]+)?(?:#(\d+))?(?:@([0-9a-f:.]+)(?:@[^#]+)?(?:#(\d+))?)?$/);

		if (!m)
			return _('Expecting: %s').format(_('valid IP address'));

		if (validation.parseIPv4(m[1])) {
			if (m[3] != null && !validation.parseIPv4(m[3]))
				return _('Expecting: %s').format(_('valid IPv4 address'));
		}
		else if (validation.parseIPv6(m[1])) {
			if (m[3] != null && !validation.parseIPv6(m[3]))
				return _('Expecting: %s').format(_('valid IPv6 address'));
		}
		else {
			return _('Expecting: %s').format(_('valid IP address'));
		}

		if ((m[2] != null && +m[2] > 65535) || (m[4] != null && +m[4] > 65535))
			return _('Expecting: %s').format(_('valid port value'));

		return true;
	},

	validateDNS: function(sec, s) {
		if (s == null || s == '')
			return true;

		var urlPattern = new RegExp('(https?|tcp|tcp\+local|quic\+local|http\+local:\\/\\/)?'+ // validate protocol
								    '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+ // validate domain name
								    '((\\d{1,3}\\.){3}\\d{1,3}))'+ // validate OR ip (v4) address
								    '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+ // validate port and path
								    '(\\?[;&a-z\\d%_.~+=-]*)?'+ // validate query string
								    '(\\#[-a-z\\d_]*)?$', 'i'); // validate fragment locator
		if (urlPattern.test(s) || s == 'localhost') {
			return true;
		}
		else {
			return _('Expecting: %s').format(_('valid DNS server'));
		}
	},

	validateRoutingDomains: function(sec, s) {
		if (s == null || s == '')
			return true;

		if (/geosite:([a-z\d]([a-z\d-@]*[a-z\d])*)+$/i.test(s)) { // for domain matches geodata such as geosite:google
			return true;
		}else if (/(domain|full):([a-z\d]([a-z\d-]*[a-z\d])*)+(\.[a-z]{2,})+$/i.test(s)) { // for domain matching with domain:google.com or full:www.google.com
			return true;
		}else if (/([a-z\d]([a-z\d-]*[a-z\d])*\.)+[a-z]{2,}$/i.test(s)) { // for domain matching such as google.com
			return true;
		}else if (/ext(:\S+){2}/i.test(s)) { // for domain matching ext file rules such as ext:geosite.dat:cn
			return true;
		}else if (/regexp:\S/i.test(s)) { // for domain matching regex
			return true;
		}
		else {
			return _('Expecting: %s').format(_('valid routing domain rule'));
		}
	},

	validateRoutingIP: function(sec, s) {
		if (s == null || s == '')
			return true;

		if (/geoip:([a-z\d]([a-z\d-@]*[a-z\d])*)+$/i.test(s)) { // for domain matches geodata such as geoip:cn
			return true;
		}else if (/^(\d+\.\d+\.\d+\.\d+)(?:\/(\d+\.\d+\.\d+\.\d+)|\/(\d{1,2}))?$/i.test(s)) { // for IP that matching IPv4 with or without mask
			return true;
		}else if (/^([0-9a-fA-F:.]+)(?:\/(\d{1,3}))?$/i.test(s)) { // for IP that matching IPv6 with or without mask
			return true;
		}else if (/ext(:\S+){2}/i.test(s)) { // for IP matching ext file rules such as ext:geoip.dat:cn
			return true;
		}
		else {
			return _('Expecting: %s').format(_('valid routing IP address'));
		}
	},

	validateShortID: function(sec, s) {
		if (s == null || s == '')
			return true;

		if (/^[0-9a-fA-F]+$/.test(s) && s.length % 2 === 0) { // the string shall be hexdecimal and the string length shall be even
			return true;
		}
		else {
			return _('Expecting: %s').format(_('hexidecimal string and length shall be even'));
		}
	}
});
