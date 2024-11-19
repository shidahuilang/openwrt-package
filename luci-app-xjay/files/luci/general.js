'use strict';
'require view';
'require form';

return view.extend({

    render:function(load_result){

        var m, s, o;
        m = new form.Map('xjay', _('Xjay'), 'Yet another xray app!');

        s = m.section(form.TypedSection, 'general');
        s.addremove = false;
        s.anonymous = true;

        o = s.option(form.Flag, 'enabled', _('Enable Xjay'), _('This enables xjay and will start xray.'));
        o.enabled = 'true';
        o.disabled = 'false';

        return m.render();
    }

});
