/*
 *  luci-theme-kucat
 *  Copyright (C) 2021-2026 The Sirpdboy Team <herboy2008@gmail.com> 
 *
 *  Have a bug? Please create an issue here on GitHub!
 *      https://github.com/sirpdboy/luci-theme-kucat/issues
 *
 *  Licensed to the public under the Apache License 2.0
 */
 
 function pdopenbar() {
    var leftBar = document.getElementById("header-bar-left");
    var rightBar = document.getElementById("header-bar-right");
    
    leftBar.style.cssText = "width:300px;display:block !important";
    rightBar.style.cssText = "width:0;display:none !important";
}

function pdclosebar() {
    var leftBar = document.getElementById("header-bar-left");
    var rightBar = document.getElementById("header-bar-right");
    
    leftBar.style.cssText = "width:0;display:none !important";
    rightBar.style.cssText = "width:50px;display:block !important";
}

document.addEventListener('DOMContentLoaded', function() {
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.key === 'ArrowLeft') pdopenbar();
        if (e.ctrlKey && e.key === 'ArrowRight') pdclosebar();
    });
});
