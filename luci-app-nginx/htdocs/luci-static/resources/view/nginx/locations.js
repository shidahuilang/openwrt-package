'use strict';
'require view';
'require fs';
'require form';
'require dom';

var enableLog = true;
var context = {"locations": []};
var confdPath = "/etc/nginx/conf.d/";

function log(content){
    if (enableLog){
        return console.log("luci-app-nginx.location: " + content);
    };
};

return view.extend({
    load: async function (){
        var fileList = await fs.list(confdPath);
        log("load: fileList is " + JSON.stringify(fileList));
        for (var i in fileList){
            if ((fileList[i].type == "file") && fileList[i].name.endsWith(".locations")){
                var fullPath = confdPath + fileList[i].name;
                var fileNameWithoutSuffix = fileList[i].name.replace(/.locations$/, "");
                var content = await fs.read_direct(fullPath);
                var obj = {
                    ".name": fileNameWithoutSuffix,
                    "content": content
                };
                context["locations"].push(obj);
            };
        };
    },
    render: function (loadResult){
        log("render: context is " + JSON.stringify(context));
        var formMap = new form.JSONMap(
            context,
            _("Location files"),
            _("All <code>.locations</code> files under <code>/etc/nginx/conf.d</code>")
        );
        var filesSection = formMap.section(
            form.TypedSection, "locations",
            _("Known location files"),
            _("We found those <code>.locations</code> files under <code>/etc/nginx/conf.d</code>")
        );
        filesSection.addremove = true;

        var filesOption = filesSection.option(
            form.TextValue, "content"
        );
        filesOption.monospace = true;
        filesOption.rows = 20;
        filesOption.cols = 70;
        return formMap.render();
    },
    handleSave: async function (ev){
        var mapNode = document.querySelector(".cbi-map");
        await dom.callClassMethod(mapNode, "save");
        log("handleSaveApply: context is " + JSON.stringify(context));
        var valueNodes = document.querySelectorAll(".cbi-value");
        var fileNamesWithoutSuffix = [];
        valueNodes.forEach(
            async function (valueNode, index, valueNodesList){
                if (valueNode.parentElement && valueNode.parentElement.getAttribute("data-section-id")){
                    var fileNameWithoutSuffix = valueNode.parentElement.getAttribute("data-section-id");
                    var fileName = confdPath + fileNameWithoutSuffix + ".locations";
                    var content = valueNode.querySelector("textarea").textContent;
                    fileNamesWithoutSuffix.push(fileNameWithoutSuffix);
                    var writeResult = await fs.write(fileName, content);
                    if (writeResult != 0){
                        log("handleSave: failed to write file %s".format(fileName));
                    };
                }
            }
        );
        context["locations"].forEach(
            async function (fileNameWithoutSuffix, index, fileNamesWithoutSuffixList){
                if (!fileNamesWithoutSuffix.includes(fileNameWithoutSuffix[".name"])){
                    var fileName = confdPath + fileNameWithoutSuffix[".name"] + ".locations";
                    var removeResult = await fs.remove(fileName);
                    if (removeResult != 0){
                        log("handleSave: failed to remove file %s".format(fileName));
                    }
                }
            }
        );
        location.reload();
    },
    handleSaveApply: null
});
