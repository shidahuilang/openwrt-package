# openwrt-smartdns

此仓库为smartdns独立仓库，为单独编译使用，可配合luci-app-smartdns一起使用。  
luci界面：[luci-app-smartdns](https://github.com/pymumu/luci-app-smartdns)

## 使用方式

注意：如下命令操作路径为openwrt源代码所在目录。  

### 复制仓库中的文件到如下目录，并执行安装

```shell
./feeds/packages/net/smartdns/
./scripts/feeds install package -a
```

### 执行openwrt配置, 选中smartdns

执行编译配置：

```shell
make menuconfig
```

* 选择路径：
 Network > smartdns

* 编译模式：

1. 若编译独立软件包，选择编译模式为`M`
1. 若编译到固件中，选择编译模式为`*`

### 执行openwrt编译

仅编译软件包：

```shell
make package/feeds/packages/smartdns/compile
```

编译固件以及软件包。

```shell
make -j8
```

## 懒人脚本

也可可执行如下命令，一次性下载smartdns。

下列命令可采用复制粘贴的方式执行， 注意目录需要在openwrt源代码目录中。

```shell
WORKINGDIR="`pwd`/feeds/packages/net/smartdns"
mkdir $WORKINGDIR -p
rm $WORKINGDIR/* -fr
wget https://github.com/pymumu/openwrt-smartdns/archive/master.zip -O $WORKINGDIR/master.zip
unzip $WORKINGDIR/master.zip -d $WORKINGDIR
mv $WORKINGDIR/openwrt-smartdns-master/* $WORKINGDIR/
rmdir $WORKINGDIR/openwrt-smartdns-master
rm $WORKINGDIR/master.zip

./scripts/feeds install -a
make menuconfig

```

上述命令完成后，可执行编译。
