<?php

include './cfg.php';
include './devinfo.php';
$str_cfg=substr($selected_config, strlen("$neko_dir/config")+1);

if(isset($_POST['neko'])){
    $dt = $_POST['neko'];
    if ($dt == 'start') shell_exec("$neko_dir/core/neko -s");
    if ($dt == 'disable') shell_exec("$neko_dir/core/neko -k");
    if ($dt == 'restart') shell_exec("$neko_dir/core/neko -r");
    if ($dt == 'clear') shell_exec("echo \"Logs has been cleared...\" > $neko_dir/tmp/neko_log.txt");
}
$neko_status=exec("uci -q get neko.cfg.enabled");
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Home - Neko</title>
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
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
            <a href="#" class="col btn btn-lg">Home</a>
            <a href="./dashboard.php" class="col btn btn-lg">Dashboard</a>
            <a href="./configs.php" class="col btn btn-lg">Configs</a>
            <a href="./settings.php" class="col btn btn-lg">Settings</a>
        </div>
    </div>
    <div class="container text-left p-3">
        <h1 class="text-center p-2 mb-3">Neko Home</h1>
        <div class="container container-bg border border-3 rounded-4 col-12 mb-4">
            <h2 class="text-center p-2">Information</h2>
            <table class="table table-borderless mb-2">
                <tbody>
                    <tr>
                        <td>Devices</td>
                        <td class="col-7"><?php echo $devices ?></td>
                    </tr>
                    <tr>
                        <td>RAM</td>
                        <td class="col-7"><?php echo "$ramUsage/$ramTotal MB" ?></td>
                    </tr>
                    <tr>
                        <td>OS Version</td>
                        <td class="col-7"><?php echo $OSVer ?></td>
                    </tr>
                    <tr>
                        <td>Kernel Version</td>
                        <td class="col-7"><?php echo $kernelv ?></td>
                    </tr>
                    <tr>
                        <td>Uptime</td>
                        <td class="col-7"><?php echo "$hours h $minutes m $seconds s"?></td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div class="container container-bg border border-3 rounded-4 col-12 mb-4">
        <h2 class="text-center p-2">Neko</h2>
            <table class="table table-borderless mb-2">
                <tbody>
                    <tr>
                        <td>Status</td>
                        <td class="d-grid">
                            <div class="btn-group col" role="group" aria-label="ctrl">            
                                <?php
                                    if($neko_status==1) echo "<button type=\"button\" class=\"btn btn-success\">RUNNING</button>\n";
                                    else echo "<button type=\"button\" class=\"btn btn-outline-danger\">DISABLED</button>\n";
                                    echo "<button type=\"button\" class=\"btn btn-warning d-grid\">$str_cfg</button>\n";
                                ?>
                            </div>
                        </td>
                    </tr>
                        <td>Control</td>
                        <form action="index.php" method="post">
                            <td class="d-grid">
                                <div class="btn-group col" role="group" aria-label="ctrl">
                                    <button type="submit" name="neko" value="start" class="btn btn<?php if($neko_status==1) echo "-outline" ?>-success <?php if($neko_status==1) echo "disabled" ?> d-grid">Enable</button>
                                    <button type="submit" name="neko" value="disable" class="btn btn<?php if($neko_status==0) echo "-outline" ?>-danger <?php if($neko_status==0) echo "disabled" ?> d-grid">Disable</button>
                                    <button type="submit" name="neko" value="restart" class="btn btn<?php if($neko_status==0) echo "-outline" ?>-warning <?php if($neko_status==0) echo "disabled" ?> d-grid">Restart</button>
                                </div>
                            </td>
                        </form>
                    </tr>
                    <tr>
                        <td>Running Mode</td>
                        <td class="d-grid">
                            <input class="form-control text-center" name="mode" type="text" placeholder="<?php echo $neko_cfg['echanced']." | ".$neko_cfg['mode'] ?>" disabled>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div class="container container-bg border border-3 rounded-4 col-12 mb-4">
            <table class="table table-borderless mb-0">
                <tbody>
                    <tr class="text-center">
                        <td class="col-2">D-Total</td>
                        <td class="col-2">U-Total</td>
                    </tr>
                    <tr class="text-center">
                        <td class="col-2"><class id="downtotal">-</class></td>
                        <td class="col-2"><class id="uptotal">-</class></td>
                    </tr>
                    <tr>
                </tbody>
            </table>
        </div>
        <div class="container container-bg border border-3 rounded-4 col-12 mb-4">
            <h2 class="text-center p-2">Neko Log</h2>
            <div class="mb-3">
            </br>
                <textarea class="form-control" id="logs" rows="10" readonly></textarea>
            </div>
            <h2 class="text-center p-2">Binary Log</h2>
            <div class="mb-3">
            </br>
                <textarea class="form-control" id="bin_logs" rows="10" readonly></textarea>
            </div>
            <div class="text-center justify-content-md-center d-grid mb-3">
                <form action="index.php" method="post">
                    <button type="submit" name="neko" value="clear" class="btn btn-success d-grid">Clear Log</button>
                </form>
            </div>
        </div>
    </div>
    <footer class="text-center">
        <p><?php echo $footer ?></p>
    </footer>
  </body>
</html>
