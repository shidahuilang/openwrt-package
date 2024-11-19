'use strict';
'require view';
'require fs';
'require form';
'require uci';
'require dom';

return view.extend({
  render: function () {
    var m, s, o;
    m = new form.Map('domain-proxy', _('Domain Proxy'));

    s = m.section(form.TypedSection, 'proxy', _('Proxy config'));
    s.anonymous = true;
    o = s.option(form.Value, 'dns', _('Dns Server'));
    o.datatype = 'ipaddrport';
    o.placeholder = '127.0.0.1:5353';

    o = s.option(
      form.DynamicList,
      'domain',
      _('Domain'),
      _('List of domains to proxy')
    );
    o.optional = true;
    o.datatype = 'host';
    o.placeholder = 'www.google.com';

    return m.render();
  },
  handleSaveApply: null,
  handleReset: null,
  handleSave: function (ev) {
    var tasks = [];

    document
      .getElementById('maincontent')
      .querySelectorAll('.cbi-map')
      .forEach(function (map) {
        tasks.push(DOM.callClassMethod(map, 'save'));
      });

    return Promise.all(tasks)
      .then(function () {
        var proxy = uci.get_first('domain-proxy', 'proxy');
        var dns = proxy.dns.replace(':', '#');
        var ssfw = [];
        proxy.domain.forEach(function (d) {
          var dt = d.trim();
          if (dt) {
            ssfw.push(`server=/${dt}/${dns}`);
            ssfw.push(`ipset=/${dt}/ssfw,ssfw6`);
          }
        });

        return fs
          .write('/etc/dnsmasq.d/ssfw.conf', ssfw.join('\n'))
          .then(function () {
            return fs.exec('/etc/init.d/dns-proxy', ['restart']);
          });
      })
      .then(function () {
        classes.ui.changes.apply(true);
      });
  },
});
