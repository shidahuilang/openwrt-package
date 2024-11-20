'use strict';
'require view';
'require form';

var enableLog = true;
function log(content){
    if (enableLog){
        return console.log("luci-app-nginx.servers: " + content);
    };
};
function isSSLEnabledInListenList(listenList){
    for (var i in listenList){
        if (listenList[i].includes("ssl")){
            return true;
        }
    }
    return false;
};

return view.extend({
    render: function (load_result){
        var formMap = new form.Map(
            "nginx",
            _("Nginx Servers"),
            _("Servers Configuration for Nginx")
        );
        var configSection = formMap.section(
            form.TypedSection, "server",
            _("All Servers"),
            _("All of the known Nginx servers.")
        );
        configSection.addremove = true;

        var listenOption = configSection.option(
            form.DynamicList, "listen",
            _("Listening on:")
        );
        var serverNameOption = configSection.option(
            form.Value, "server_name",
            _("Server Name:")
        );
        serverNameOption.optional = true;

        var uciManageSSLOption = configSection.option(
            form.Value, "uci_manage_ssl",
            _("SSL Managed By UCI:"),
            _("Set to any value other than self-signed to manage it yourself.")
        );
        var sslCertificatePathOption = configSection.option(
            form.Value, "ssl_certificate",
            _("SSL Certificate:")
        );
        var sslCertificateKeyPathOption = configSection.option(
            form.Value, "ssl_certificate_key",
            _("SSL Certificate Key:")
        );
        var sslSessionCacheOption = configSection.option(
            form.Value, "ssl_session_cache",
            _("SSL Session Cache Option:")
        );
        sslSessionCacheOption.optional = true;
        var sslSessionTimeoutOption = configSection.option(
            form.Value, "ssl_session_timeout",
            _("SSL Session Timeout:")
        );
        sslSessionTimeoutOption.optional = true;

        var returnOption = configSection.option(
            form.Value, "return",
            _("Return:")
        );
        returnOption.optional = true;
        var accessLogOption = configSection.option(
            form.Value, "access_log",
            _("Access Log:")
        );
        accessLogOption.optional = true;

        return formMap.render();
    }
});
