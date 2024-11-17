<?php

ob_start();
include './cfg.php';
$cfg_path = "/etc/neko/config";
$proxy_path = "/etc/neko/proxy_provider";
$rule_path = "/etc/neko/rule_provider";
$arrPath = array($cfg_path, $proxy_path, $rule_path, "BACKUP CONFIG", "RESTORE CONFIG");
function create_table($path){
  $arr_table = glob("$path/*.yaml");
  foreach ($arr_table as $file) {
    $file_info = explode("/", $file);
    $file_dir = $file_info[3];
    $file_name = explode(".", $file_info[4]);
    $out_table = "";
    $out_table .= "            <tr class=\"text-center\">\n";
    $out_table .= "              <td class=\"col-4\">".$file_info[4]." </br>[ ".formatSize(filesize($file))." - ".date('Y-m-d H:i:s', ((7*3600)+filemtime($file)))." ]"."</td>\n";
    $out_table .= "              <td class=\"col-2\">\n";
    $out_table .= "                <form action=\"manager.php\" method=\"post\">\n";
    $out_table .= "                  <div class=\"btn-group col\" role=\"group\" aria-label=\"ctrl\">\n";
    $out_table .= "                    <button type=\"submit\" name=\"file_action\" value=\"down@".$file."\" class=\"btn btn-info d-grid\"><i class=\"fa fa-download\"></i>Download</button>\n";
    # $out_table .= "                    <button type=\"submit\" name=\"file_action\" value=\"ren@".$file."\" class=\"btn btn-warning d-grid\">RENAME</button>\n";
    # $out_table .= "                    <button type=\"submit\" name=\"file_action\" value=\"del@".$file."\" class=\"btn btn-danger d-grid\"><i class=\"fa fa-trash\"></i>DELETE</button>\n";
    $out_table .= "                    <button type=\"button\" onclick=\"topFunction()\" class=\"btn btn-primary d-grid\" data-bs-toggle=\"modal\" data-bs-target=\"#".$file_dir."_".$file_name[0]."\"><i class=\"fa fa-gear\"></i>Option</button>\n";
    $out_table .= "                  </div>\n";
    $out_table .= "                </form>\n";
    $out_table .= "              </td>\n";
    $out_table .= "            </tr>\n";
    echo $out_table;
  }
  
}
function create_modal($path) {
  $arr_modal = glob("$path/*.yaml");
  foreach ($arr_modal as $file) {
    $file_info = explode("/", $file);
    $file_dir = $file_info[3];
    $file_name = explode(".", $file_info[4]);
    $out_modal = "";
    $out_modal .= "<div class=\"modal fade\" data-bs-keyboard=\"false\" id=\"".$file_dir."_".$file_name[0]."\" tabindex=\"1\" aria-labelledby=\"modal_".$file_dir."_".$file_name[0]."\" aria-hidden=\"true\">\n";
    $out_modal .= "        <div class=\"modal-dialog modal-xl modal-fullscreen-md-down\">\n";
    $out_modal .= "          <div class=\"modal-content\">\n";
    $out_modal .= "            <div class=\"modal-header\">\n";
    $out_modal .= "              <h5 class=\"modal-title\" id=\"modal_".$file_dir."_".$file_name[0]."\">File Information</h5>\n";
    $out_modal .= "              <button type=\"button\" class=\"btn-close\" data-bs-dismiss=\"modal\" aria-label=\"Close\"></button>\n";
    $out_modal .= "            </div>\n";
    $out_modal .= "            <form action=\"manager.php\" method=\"post\">\n";
    $out_modal .= "            <div class=\"modal-body\">\n";
    $out_modal .= "              <a>Name : ".$file_info[4]."</a></br>\n";
    $out_modal .= "              <a>File Size : ".formatSize(filesize($file))."</a></br>\n";
    $out_modal .= "              <a>Last Modified : ".date('Y-m-d H:i:s', ((7*3600)+filemtime($file)))."</a></br>\n";
    $out_modal .= "              <div class=\"col input-group justify-content-md-center\">\n";
    $out_modal .= "                <textarea class=\"form-control\" name=\"form_".$file_dir."_".$file_name[0]."\" rows=\"15\">".shell_exec("cat $file")."</textarea>\n";
    $out_modal .= "              </div>\n";
    $out_modal .= "            </div>\n";
    $out_modal .= "            <div class=\"modal-footer\">\n";
    $out_modal .= "              <button type=\"submit\" name=\"file_action\" value=\"del@".$file."\" class=\"btn btn-danger d-grid\"><i class=\"fa fa-trash\"></i>Delete</button>\n";
    $out_modal .= "              <button type=\"submit\" name=\"file_action\" value=\"save@".$file."\" class=\"btn btn-success d-grid\"><i class=\"fa fa-floppy-o\"></i>Save</button>\n";
    $out_modal .= "              <button type=\"button\" class=\"btn btn-secondary d-grid\" data-bs-dismiss=\"modal\"><i class=\"fa fa-times\"></i>Close</button>\n";
    $out_modal .= "            </div>\n";
    $out_modal .= "              </form>\n";
    $out_modal .= "          </div>\n";
    $out_modal .= "        </div>\n";
    $out_modal .= "      </div>\n";
    echo $out_modal;
  }
}
function up_controller($dir){
  $target_file = $dir . "/" . basename($_FILES["file_upload"]["name"]);
  $upload_stat = 1;
  $fileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));
  $str_prnt = "";
  if (file_exists($target_file)) {
    $str_prnt = "File already exists.\n";
    $upload_stat = 0;
  }
  if (!in_array($fileType, ['yaml', 'yml'])) {
    $str_prnt = "Only <b>.yaml</b> or <b>.yml</b> files are allowed.";
    $upload_stat = 0;
  }
  if ($_FILES["file_upload"]["size"] > 10485760) {
    $str_prnt = "Max file size is 10MB.";
    $upload_stat = 0;
  }
  if (strpos($target_file, ' ') !== false) {
    $str_prnt = "File names with spaces are not allowed.";
    $upload_stat = 0;
  }
  if ($upload_stat == 0) {
    echo $str_prnt."</br>File not uploaded.";
  }
  else {
    if (move_uploaded_file($_FILES["file_upload"]["tmp_name"], $target_file)) {
      $dir_info = explode("/", $dir);
      echo "File <b>" . htmlspecialchars(basename($_FILES["file_upload"]["name"])) . "</b> has been uploaded to directory <b>" . $dir_info[3] . "</b>";
    } else {
      echo "ERROR uploading your files.";
    }
  }
}

function action_controller($action_str) {
  $action = explode("@", $action_str);
  $file_path = $action[1];
  $file_info = explode("/", $file_path);
  switch ($action[0]) {
    case "del":
      echo "File <b>".$file_info[4]."</b> from directory <b>".$file_info[3]."</b> has ben <b>deleted</b>";
      shell_exec("rm -r $file_path");
      break;
    case "save":
      $dir = $file_info[3];
      $filename = explode(".", $file_info[4]);
      $formname = "form_".$dir."_".$filename[0];
      $form = $_POST[$formname];
      shell_exec("echo \"$form\" > $file_path");
      echo "File <b>".$file_info[4]."</b> from directory <b>".$dir."</b> has ben <b>saved</b>";
      break;
    case "ren":
      echo $action[0]." - ".$file_path;
      break;
    case "down":
      echo $action[0]." - ".$file_path;
      if (file_exists($file_path)) {
        echo $action[0]." - ".$file_path;

        ob_clean();
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename='.basename($file_info[4]));
        header('Expires: 0');
        header('Content-Length: ' . filesize($file_path));
        readfile($file_path);
      }
      flush();
      exit();
      break;
    default:
      echo "undefined";
  }
}

function formatSize($bytes) {
  if ($bytes >= 1073741824) {
      return number_format($bytes / 1073741824, 2) . ' GB';
  } elseif ($bytes >= 1048576) {
      return number_format($bytes / 1048576, 2) . ' MB';
  } elseif ($bytes >= 1024) {
      return number_format($bytes / 1024, 2) . ' KB';
  } else {
      return number_format($bytes, 2) . ' B';
  }
}
function restore_controller(){
  $target_file = "/etc/neko/" . basename($_FILES["file_upload"]["name"]);
  $upload_stat = 1;
  $fileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));
  $str_prnt = "";
  if ($fileType !== 'gz') {
    $str_prnt = "</br>Only <b>.tar.gz</b> files are allowed.";
    $upload_stat = 0;
  }
  if (strpos($target_file, ' ') !== false) {
    $str_prnt = "</br>File names with spaces are not allowed.";
    $upload_stat = 0;
  }
  if ($upload_stat == 0) {
    echo $str_prnt."</br>File not uploaded.";
    return $target_file."tmp.gz";
  }
  else {
    if (move_uploaded_file($_FILES["file_upload"]["tmp_name"], $target_file)) {
      echo "</br>File <b>" . htmlspecialchars(basename($_FILES["file_upload"]["name"])) . "</b> has been uploaded.</br>";
      return $target_file;
    } 
    else {
      echo "ERROR uploading your files.";
    }
  }
}

function backupConfig(){
  shell_exec("/etc/neko/core/neko -b");
  $dir_path = "/tmp";
  $file_name = shell_exec("ls /tmp/ | grep neko");
  $file_path = trim("$dir_path/$file_name");
  echo $file_path;
  if (file_exists($file_path)) {
    echo "Backuping configuration, please wait...";
    ob_clean();
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename='.basename($file_name));
    header('Content-Transfer-Encoding: binary');
    header('Expires: 0');
    header('Cache-Control: must-revalidate');
    header('Pragma: public');
    header('Content-Length: ' . filesize($file_path));
  }
  ob_clean();
  flush();
  sleep (2);
  readfile($file_path);
  shell_exec("rm -r $file_path");
  exit;
}

function restoreConfig(){
  echo "Restoring your configuration...";
  $str = restore_controller();
  if (file_exists($str)){
    shell_exec("/etc/neko/core/neko -x");
    echo "Your configuration has ben restored.";
  }
  else{
    echo "</br>Can't restore your configuration";
  }
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
    <link href="./assets/css/font-awesome.min.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
  </head>
  <body class="container-bg">
      <div>
        <?php 
        create_modal($cfg_path);
        create_modal($proxy_path);
        create_modal($rule_path);
        ?>
      </div>
    <div class="container-bg text-center"></br>
        <form action="manager.php" method="post" enctype="multipart/form-data">
        <div class="container container-bg border border-3 rounded-4 col-12 mb-4"></br>
          <h3>Upload & Backup file</h3>
          <a><?php
              if(isset($_POST["path_selector"])) {
                if ($_POST['path_selector'] == 'Option') echo "Please, select the correct Options!!!";
                elseif ($_POST['path_selector'] == 'BACKUP CONFIG') backupConfig();
                elseif ($_POST['path_selector'] == 'RESTORE CONFIG') restoreConfig();
                else up_controller($_POST['path_selector']);
              }
              if(isset($_POST["file_action"])) {
                action_controller($_POST["file_action"]);
              }?>
          </a>
          <table class="table table-borderless">
              <tbody>
                  <tr class="text-center">
                      <td class="col-3">
                      <div class="mb-3">
                          <input class="form-control" type="file" name="file_upload" accept=".yaml,.yml,.tar.gz">
                        </div>
                      </td>
                      <td class="col-2">
                        <select class="form-select" name="path_selector" aria-label="themex">
                          <option selected>Option</option>
<?php foreach ($arrPath as $file) echo "                          <option value=\"".$file.'">'.$file."</option>\n" ?>
                        </select>
                      </td>
                      <td class="col-2">
                        <input class="btn btn-info d-grid col-8" type="submit" value="Apply">
                      </td>
                  </tr>
              </tbody>
          </table>
          <a><b>NOTE</b></a></br>
          <a>Restore your configuration is destroying our old <b>configuration</b> at neko directory!!!</a></br>
          <a>Backup is include of directory <b>configs, proxy_provider,</b> and<b> rule_provider.</b></a></br></br>
          </div>
      </form></br>
      <div class="container container-bg border border-3 rounded-4 col-12 mb-4"></br>
      <h3>Config files</h3>
      <table class="table table-borderless">
        <tbody>
          <tr class="text-center">
            <tr class="text-center">
              <td class="col-4">Files</td>
              <td class="col-2">Action</td>
            </tr>
<?php create_table($cfg_path) ?>
          </tr>
        </tbody>
      </table>
      </div>
      <div class="container container-bg border border-3 rounded-4 col-12 mb-4"></br>
      <h3>Proxy Provider files</h3>
      <table class="table table-borderless">
        <tbody>
          <tr class="text-center">
            <tr class="text-center">
              <td class="col-4">Files</td>
              <td class="col-2">Action</td>
            </tr>
<?php create_table($proxy_path) ?>
          </tr>
        </tbody>
      </table>
      </div>
      <div class="container container-bg border border-3 rounded-4 col-12 mb-4"></br>
      <h3>Rules Provider files</h3>
      <table class="table table-borderless">
        <tbody>
          <tr class="text-center">
            <tr class="text-center">
              <td class="col-4">Files</td>
              <td class="col-2">Action</td>
            </tr>
<?php create_table($rule_path) ?>
          </tr>
        </tbody>
      </table>
      </div></br></br></br></br></br>
    </div>
  </body>
  <script>
function topFunction() {
  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}
    </script>
</html>
