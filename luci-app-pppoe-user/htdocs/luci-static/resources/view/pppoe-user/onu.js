'use strict';
'require view';
'require form';
'require ui';

return view.extend({
  render: function () {
    var m, s, o;
    
    m = new form.Map('pppoe-user', _(''), _(''));
    
    // User section
    s = m.section(form.GridSection, 'user', _('ONU List'));
    s.anonymous = true;
    s.nodescriptions = true
    
    // Username field
    o = s.option(form.Value, 'username', _('Account'));
    o.readonly = true;
    
    // Service Name field (dropdown)
    o = s.option(form.Value, 'servicename', _('Service Name'));
    o.modalonly = true;
    o.readonly = true;
    
    // Password field
    o = s.option(form.Value, 'password', _('Password'));
    o.password = true;
    o.modalonly = true;
    o.readonly = true;
    
    // MAC Address field (dropdown)
    o = s.option(form.Value, 'macaddr', _('MAC Address'));
    o.password = true;
    o.modalonly = true;
    o.readonly = true;
    
    // Package field (dropdown)
    o = s.option(form.Value, 'package', _('Package'));
    o.readonly = true;
    
    // Upload Speed field (dropdown)
    var o = s.option(form.Value, 'urate', _('Upload Speed'));
    o.modalonly = true;
    o.readonly = true;
    
    // Download Speed field (dropdown)
    var o = s.option(form.Value, 'drate', _('Download Speed'));
    o.modalonly = true;
    o.readonly = true;
    
    // Concurrent Connection Number Segment (dropdown menu)
    var o = s.option(form.Value, 'connect', _('Connection Number'));
    o.modalonly = true;
    o.readonly = true;
    
    // OLT field (dropdown)
    var o = s.option(form.Value, 'olt', _('OLT'));
    o.value('1', 'OLT 1');
    o.value('2', 'OLT 2');
    o.value('3', 'OLT 3');
    o.value('4', 'OLT 4');
    o.value('5', 'OLT 5');
    o.value('6', 'OLT 6');
    o.value('7', 'OLT 7');
    o.value('8', 'OLT 8');
    o.value('9', 'OLT 9');
    o.value('10', 'OLT 10');
    o.value('11', 'OLT 11');
    o.value('12', 'OLT 12');
    o.value('13', 'OLT 13');
    o.value('14', 'OLT 14');
    o.value('15', 'OLT 15');
    o.value('16', 'OLT 16');
    o.value('17', 'OLT 17');
    o.value('18', 'OLT 18');
    o.value('19', 'OLT 19');
    o.value('20', 'OLT 20');
    
    // PON field (dropdown)
    var o = s.option(form.Value, 'pon', _('PON'));
    o.value('1', 'PON 1');
    o.value('2', 'PON 2');
    o.value('3', 'PON 3');
    o.value('4', 'PON 4');
    o.value('5', 'PON 5');
    o.value('6', 'PON 6');
    o.value('7', 'PON 7');
    o.value('8', 'PON 8');
    o.value('9', 'PON 9');
    o.value('10', 'PON 10');
    o.value('11', 'PON 11');
    o.value('12', 'PON 12');
    o.value('13', 'PON 13');
    o.value('14', 'PON 14');
    o.value('15', 'PON 15');
    o.value('16', 'PON 16');
    
    // Serial Number field (dropdown)
    o = s.option(form.Value, 'sn', _('S/N'));
    o.placeholder = 'ONT Serial Number';
    
    // Submit button
    return m.render();
  },
    handleSave: null,
    handleSaveApply: null,
    handleReset: null
});
