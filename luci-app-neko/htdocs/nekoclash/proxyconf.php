<?php

include './cfg.php';
$dirPath = "$neko_dir/proxy_provider";
$tmpPath = "$neko_www/lib/tmpProxy.txt";
$proxyPath = "";
$arrFiles = array();
$arrFiles = glob("$dirPath/*.yaml");
$strProxy = "";
$strNewProxy = "";
//print_r($arrFiles);
if(isset($_POST['proxycfg'])){
  $dt = $_POST['proxycfg'];
  $strProxy = shell_exec("cat $dt");
  $proxyPath = $dt;
  shell_exec("echo $dt > $tmpPath");
}
if(isset($_POST['newproxycfg'])){
  $dt = $_POST['newproxycfg'];
  $strNewProxy = $dt;
  $tmpData = exec("cat $tmpPath");
  shell_exec("echo \"$strNewProxy\" > $tmpData");
  shell_exec("rm $tmpPath");
}
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Proxy - Neko</title>
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
  </head>
  <body class="container-bg">
    <div class="container text-center justify-content-md-center mb-3"></br>
        <form action="proxyconf.php" method="post">
            <div class="container text-center justify-content-md-center">
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <select class="form-select" name="proxycfg" aria-label="themex">
                        <option selected>Select Proxy</option>
                        <?php foreach ($arrFiles as $file) echo "<option value=\"".$file.'">'.$file."</option>" ?>
                      </select>
                      <input class="btn btn-info" type="submit" value="Select">
                    </div>
                </div>
            </div>
        </form>
        <div class="container mb-3">
        <form action="proxyconf.php" method="post">
            <div class="container text-center justify-content-md-center">
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <?php if(!empty($file)) echo "<h5>$proxyPath</h5>" ?>
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <textarea class="form-control" name="newproxycfg" rows="16"><?php if (!empty($strProxy))echo $strProxy; else echo $strNewProxy; ?></textarea>
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                        <input class="btn btn-info" type="submit" value="Save Proxy">
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <?php if(!empty($strNewProxy)) echo "<h5>Proxy SUCCESSFULLY SAVED</h5>" ?>
                    </div>
                </div>
            </div>
        </form>
        </div>
    </div>
  </body>
</html>
