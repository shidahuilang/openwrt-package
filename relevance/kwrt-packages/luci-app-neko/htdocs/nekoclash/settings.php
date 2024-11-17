<?php

include './cfg.php';

$themeDir = "$neko_www/assets/theme";
$arrFiles = array();
$arrFiles = glob("$themeDir/*.css");

$neko_version = exec("opkg list-installed | grep luci-app-neko | cut -d ' - ' -f3");
$neko_latest = exec("curl -m 5 -f -s https://raw.githubusercontent.com/nosignals/openwrt-neko/main/luci-app-neko/Makefile | grep PKG_VERSION: | cut -d= -f2");
$stat = 0;
if ($neko_version == $neko_latest){
    $stat = 0;
}
else {
    $stat = 1;
}

for($x=0;$x<count($arrFiles);$x++) $arrFiles[$x] = substr($arrFiles[$x], strlen($themeDir)+1);

if(isset($_POST['themechange'])){
    $dt = $_POST['themechange'];
    shell_exec("uci set neko.cfg.theme='$dt' && uci commit neko");
    $neko_theme = $dt;
}
if(isset($_POST['fw'])){
    $dt = $_POST['fw'];
    if ($dt == 'enable') shell_exec("uci set neko.cfg.new_interface='1' && uci commit neko");
    if ($dt == 'disable') shell_exec("uci set neko.cfg.new_interface='0' && uci commit neko");
}
if(isset($_POST['neko'])){
    $dt = $_POST['neko'];
    if ($dt == 'update'){
        updateNeko();
    }
}
function updateNeko(){
    $neko_latest = exec("curl -m 5 -f -s https://raw.githubusercontent.com/nosignals/openwrt-neko/main/luci-app-neko/Makefile | grep PKG_VERSION: | cut -d= -f2");
    if(!empty($neko_latest)){
        $url_update = "https://github.com/nosignals/openwrt-neko/releases/download/luci-app-neko_".$neko_latest."/luci-app-neko_".$neko_latest."_all.ipk";
        $str_update = <<<EOF
        #/bin/bash
        wget -O /tmp/neko.ipk $url_update
        cd /tmp
        opkg remove luci-app-neko
        opkg install neko.ipk
        rm -r /tmp/neko.ipk
        EOF;
        echo "<h1>UPDATING NEKO TO VERSION ".$neko_latest."</br>";
        echo "DONT CLOSE THIS TAB</br></h1>";
        echo "if in 30s not showing notification, you can try again update";
        file_put_contents('/tmp/neko_update', $str_update);
        exec("chmod +x /tmp/neko_update");
        shell_exec("/tmp/neko_update");
        echo "<h1>Done Updating, Please reload this tab</h1>";
        shell_exec("rm /tmp/neko_update");
    }
    else{
        echo "<h1>Check your Internet Connection!!!.</h1>";
    }
}
$fwstatus=shell_exec("uci get neko.cfg.new_interface");
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Settings - Neko</title>
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
  </head>
  <body>
    <div class="container-sm text-center col-8">
	    <img src="./assets/img/neko.png" class="img-fluid mb-5">
    </div>
    <div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
        <div class="row">
            <a href="./" class="col btn btn-lg">Home</a>
            <a href="./dashboard.php" class="col btn btn-lg">Dashboard</a>
            <a href="./configs.php" class="col btn btn-lg">Configs</a>
            <a href="#" class="col btn btn-lg">Settings</a>
        </div>
    </div>
    <div class="container text-left p-3">
        <h1 class="text-center p-2 mb-3">Settings</h1>
        <div class="container container-bg border border-3 rounded-4 col-12 mb-4">
        <h2 class="text-center p-2 mb-3">Theme Setting</h2>
            <form action="settings.php" method="post">
                <div class="container text-center justify-content-md-center">
                    <div class="row justify-content-md-center">
                        <div class="col mb-3 justify-content-md-center">
                          <select class="form-select" name="themechange" aria-label="themex">
                                <option selected>Change Theme (<?php echo $neko_theme ?>)</option>
                                <?php foreach ($arrFiles as $file) echo "<option value=\"".$file.'">'.$file."</option>" ?>
                          </select>
                        </div>
                        <div class="row justify-content-md-center">
                            <div class="col justify-content-md-center mb-3">
                              <input class="btn btn-info" type="submit" value="Change Theme">
                            </div>
                        </div>
                    </div>
                </div>
            </form>
            <h2 class="text-center p-2 mb-3">Software Information</h2>
            <table class="table table-borderless mb-3">
                <tbody>
                    <tr>
                        <td class="col-2">Auto Reload Firewall</td>
                        <form action="settings.php" method="post">
                            <td class="d-grid">
                                <div class="btn-group col" role="group" aria-label="ctrl">
                                    <button type="submit" name="fw" value="enable" class="btn btn<?php if($fwstatus==1) echo "-outline" ?>-success <?php if($fwstatus==1) echo "disabled" ?> d-grid">Enable</button>
                                    <button type="submit" name="fw" value="disable" class="btn btn<?php if($fwstatus==0) echo "-outline" ?>-danger <?php if($fwstatus==0) echo "disabled" ?> d-grid">Disable</button>
                                </div>
                            </td>
                        </form>
                    </tr>
                    <tr>
                        <td class="col-1">Client Version</td>
                        <td class="col-4">
                            <div class="form-control text-center" id="cliver">-</div>
                        </td>
                        <td class="col-1">
                            <form action="settings.php" method="post">
                                <button type="submit" name="neko" value="update" class="btn btn-danger <?php if($stat==0) echo "disabled " ?>col-10">Update</button>
                            </form>
                        </td>
                    </tr>
                    <tr>
                        <td class="col-1">Core Version</td>
                        <td class="col-4">
                            <div class="form-control text-center" id="corever">-</div>
                        </td>
                        <td class="col-1">
                            <a class="btn btn-danger col-10" target="_blank" href="https://github.com/nosignals/openwrt-neko/releases">Update</a>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div class="container container-bg border border-3 rounded-4 col-12 mb-4">
            <h2 class="text-center p-2 mb-3">About</h2>
            <div class="container text-center border border-3 rounded-4 col-10 mb-4">
                </br>
                <h5 class="mb-3">NekoClash</h5>
                <p>NekoClash is a family friendly Clash Proxy tool, this tool makes it easy for users to use Clash Proxy, and User can modify your own Theme based Bootstrap, inspired by OpenClash Tools. NekoClash has writen by PHP, and BASH.</p>
                <p>This tool aims to make it easier to use Clash Proxy</p>
                <p>If you have questions or feedback about NekoClash you can contact me on the <b>DBAI Discord Server</b> link below</p>
                <h5 class="mb-3">External Links</h5>
                <table class="table table-borderless callout mb-5">
                    <tbody>
                        <tr class="text-center">
                            <td>Discord</td>
                            <td>Github</td>
                        </tr>
                        <tr class="text-center callout">
                            <td><a class="btn btn-outline-secondary col-10" target="_blank" href="https://discord.gg/vtV5QSq6D6">DBAI</a></td>
                            <td><a class="btn btn-outline-secondary col-10" target="_blank" href="https://github.com/nosignals">nosignals</a></td>
                        </tr>
                        <tr class="text-center">
                            <td>FB Group</td>
                            <td>Clash</td>
                        </tr>
                        <tr class="text-center">
                            <td><a class="btn btn-outline-secondary col-10" target="_blank" href="https://www.facebook.com/groups/indowrt">indoWRT</a></td>
                            <td><a class="btn btn-outline-secondary col-10" target="_blank" href="https://github.com/MetaCubeX/mihomo">Mihomo</a></td>
                        </tr>
                    </tbody>
                </table>
                <p>Please don't <b>CHANGE</b> or <b>REMOVE</b> this Credit!.</p>
            </div>
        </div>
    </div>
    <footer class="text-center">
        <p><?php echo $footer ?></p>
    </footer>
  </body>
</html>
