<?php

include './cfg.php';

$neko_cfg['ctrl_host']=$_SERVER['SERVER_NAME'];
$neko_cfg['ctrl_port']=preg_replace('/\s+/', '', (shell_exec("cat $selected_config | grep external-c | awk '{print $2}' | cut -d: -f2")));
$yacd_link=$neko_cfg['ctrl_host'].':'.$neko_cfg['ctrl_port'].'/ui/meta?hostname='.$neko_cfg['ctrl_host'].'&port='.$neko_cfg['ctrl_port'].'&secret='.$neko_cfg['secret'];
$meta_link=$neko_cfg['ctrl_host'].':'.$neko_cfg['ctrl_port'].'/ui/metacubexd?hostname='.$neko_cfg['ctrl_host'].'&port='.$neko_cfg['ctrl_port'].'&secret='.$neko_cfg['secret'];

?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard - Neko</title>
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
  </head>
  <body>
    <div class="container-sm text-center col-8">
	    <img src="./assets/img/neko.png" class="img-fluid mb-5">
    </div>
    <div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
        <div class="row">
            <a href="./" class="col btn btn-lg">Home</a>
            <a href="#" class="col btn btn-lg">Dashboard</a>
            <a href="./configs.php" class="col btn btn-lg">Configs</a>
            <a href="./settings.php" class="col btn btn-lg">Settings</a>
        </div>
    </div>
    <div class="container text-left p-3">
        <h1 class="text-center p-2 mb-3">Dashboard</h1>
        <div class="container-fluid container-bg border border-3 rounded-4 mb-3">
            <h2 class="text-center p-2">Meta YACD</h2>
            <table class="table table-borderless callout mb-2">
                <tbody>
                    <tr class="text-center callout">
                        <td><a class="btn btn-outline-info" target="_blank" href="http://<?=$yacd_link ?>">META - YACD</a></td>
                        <td><a class="btn btn-outline-info" target="_blank" href="http://<?=$meta_link ?>">METACUBEXD</a></td>
                    </tr>
                </tbody>
            </table>
            <div class="container h-100 mb-5">
                <iframe class="border border-3 rounded-4 w-100" height="700" src="http://<?=$yacd_link ?>" title="yacd" allowfullscreen></iframe>
            </div>
        </div>
    </div>
    <footer class="text-center">
        <p><?php echo $footer ?></p>
    </footer>
  </body>
</html>