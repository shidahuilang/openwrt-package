'use strict';
'require view';
'require poll';
'require rpc';
'require fs';
'require uci';

var enableLog = true;
var pollIntervalSecs = 5;
var context = {
    server: "unknown",
    httpsRedirectEnabled: false,
    serversCount: 0,
    curlInstalled: false
};
var expectServiceObject = {
    "nginx": {
        "instances": {
            "instance1": {}
        }
    }
};
function log(content){
    if (enableLog){
        return console.log("luci-app-nginx.main: " + content);
    };
};
function toDict(string, kvSpliter){
    var dict = {};
    string.split(/\r?\n|\r/g).forEach(
        function (line, index, array){
            if (line.includes(kvSpliter)){
                var kv = line.split(kvSpliter, 2);
                dict[kv[0].toLowerCase()] = kv[1];
            };
        }
    );
    return dict;
};
function filterServiceFunction(data, args, extraArgs){
    log("filterFunction: data is " + JSON.stringify(data));
    log("filterFunction: args is " + JSON.stringify(args));
    log("filterFunction: extraArgs is " + extraArgs);
    if (
        (args.name == "nginx") &&
        (typeof data?.instances?.instance1?.running == "boolean")
    ){
        if (data.instances.instance1.running){
            return "running";
        }
        else {
            return "stopped";
        };
    };
    return "unknown";
};
var getServiceStatus = rpc.declare({
    object: "service",
    method: "list",
    params: ["name"],
    expect: expectServiceObject,
    filter: filterServiceFunction
});
async function updateStatusContent(){
    var result = await getServiceStatus("nginx");
    log("updateStatusContent: trying to update nginx status to " + result);
    var statusContent = document.getElementById("nginx-status-content");
    log("updateStatusContent: found div#nginx-status-content: " + statusContent);
    if (statusContent){
        switch (result){
            case "running":
                statusContent.textContent = _("Running");
                statusContent.style.color = "green";
                break;
            case "stopped":
                statusContent.textContent = _("Stopped");
                statusContent.style.color = "red";
                break;
            default:
                statusContent.textContent = _("Unknown");
                statusContent.style.color = "orange";
                break;
        };
    };
};
return view.extend({
    handleSaveApply: null,
    handleSave: null,
    handleReset: null,
    load: async function (){
        var curlExec = "/usr/bin/curl";
        var curlStatus = await fs.stat(curlExec);
        log("curlStatus is " + JSON.stringify(curlStatus));
        context.curlInstalled = ((curlStatus.type == "file") && (curlStatus.mode == 33261));
        log("load: context.curlInstalled is " + context.curlInstalled);
        if (context.curlInstalled){
            var curlResult = await fs.exec_direct(curlExec, ["-I", "-s", "http://" + location.host]);
            log("load: curlResult is " + curlResult);
            var headers = toDict(curlResult, ": ");
            log("load: headers is " + JSON.stringify(headers));
            var locationInHeaders = headers["location"];
            if (locationInHeaders){
                if (locationInHeaders.startsWith("https://" + location.host)){
                    context.httpsRedirectEnabled = true;
                };
            };
            var serverInHeaders = headers["server"];
            if (serverInHeaders){
                context.server = serverInHeaders;
            };
        };
        await uci.load("nginx");
        context.serversCount = uci.sections("nginx", "server").length;
        uci.unload();
    },
    render: function (loadResults){
        log("render: loadResults is " + loadResults);

        var statusTitle = E("div", {"id":"nginx-status-title"}, _("Nginx status:"));
        statusTitle.style.display = "inline-block";
        var statusContent = E("div", {"id": "nginx-status-content"}, _("Unknown"));
        statusContent.style.color = "orange";
        statusContent.style.display = "inline-block";
        statusContent.style.marginLeft = "10px";
        var serviceControlLinkTitle = E(
            "div",
            {"id": "nginx-service-control"},
            "%s -> %s".format(_("System"), _("Startup"))
        );
        serviceControlLinkTitle.style.display = "inline-block";
        var serviceControlLink = E(
            "a",
            {"href": location.href.replace(location.pathname, "/cgi-bin/luci/admin/system/startup")}
        );
        serviceControlLink.appendChild(serviceControlLinkTitle);;
        serviceControlLink.style.marginLeft = "25px";
        var statusElement = E("div",{"id": "nginx-status"});
        statusElement.appendChild(statusTitle);
        statusElement.appendChild(statusContent);
        statusElement.appendChild(serviceControlLink);
        statusElement.style.marginTop = "25px";

        var luciServerTitle = E("div", _("LuCI on Nginx:"));
        luciServerTitle.style.display = "inline-block";
        var luciServerStatus;
        if (context.curlInstalled){
            luciServerStatus = E("div", _(context.server.startsWith("nginx")?"Yes":"No"));
            luciServerStatus.style.color = context.server.startsWith("nginx")?"green":"red";
        } else {
            luciServerStatus = E("div", _("Install <code>curl</code> for this info."));
            luciServerStatus.style.color = "orange";
        };
        luciServerStatus.style.display = "inline-block";
        luciServerStatus.style.marginLeft = "10px";
        var luciServerLinkTitle = E(
            "div",
            {"id": "nginx-luci-link"},
            "%s -> %s -> %s".format(_("Services"), _("Nginx"), _("Servers"))
        );
        luciServerLinkTitle.style.display = "inline-block";
        var luciServerLink = E(
            "a",
            {"href": location.href.replace(location.pathname, "/cgi-bin/luci/admin/services/nginx/servers")}
        )
        luciServerLink.appendChild(luciServerLinkTitle);
        luciServerLink.style.marginLeft = "25px";
        var luciServerElement = E("div", {"id": "nginx-luci-status"});
        luciServerElement.appendChild(luciServerTitle);
        luciServerElement.appendChild(luciServerStatus);
        luciServerElement.appendChild(luciServerLink);
        luciServerElement.style.marginTop = "25px";

        var httpsRedirectTitle = E("div", _("Https Redirect Enabled:"));
        httpsRedirectTitle.style.display = "inline-block";
        var httpsRedirectStatus;
        if (context.curlInstalled){
            httpsRedirectStatus = E("div", _(context.httpsRedirectEnabled?"Yes":"No"));
            httpsRedirectStatus.style.color = context.httpsRedirectEnabled?"green":"red";
        } else {
            httpsRedirectStatus = E("div", _("Install <code>curl</code> for this info."));
            httpsRedirectStatus.style.color = "orange";
        };
        httpsRedirectStatus.style.display = "inline-block";
        httpsRedirectStatus.style.marginLeft = "10px";
        var httpsRedirectElement = E("div", {"id": "nginx-https-redirect"});
        httpsRedirectElement.appendChild(httpsRedirectTitle);
        httpsRedirectElement.appendChild(httpsRedirectStatus);
        httpsRedirectElement.style.marginTop = "25px";

        var serversCountTitle = E("div", _("Running Servers Count:"));
        serversCountTitle.style.display = "inline-block";
        var serversCountStatus = E("div", "%d".format(context.serversCount));
        serversCountStatus.style.display = "inline-block";
        serversCountStatus.style.marginLeft = "10px";
        var serversCountElement = E("div", {"id": "nginx-servers-count"});
        serversCountElement.appendChild(serversCountTitle);
        serversCountElement.appendChild(serversCountStatus);
        serversCountElement.style.marginTop = "25px";

        poll.add(updateStatusContent, pollIntervalSecs);
        return E([
            statusElement, luciServerElement, httpsRedirectElement, serversCountElement
        ]);
    }
});
