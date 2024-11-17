#!/bin/sh
# 将 $2 中的所有单引号替换为双引号

# 发送处理后的命令
rec=$(sendat $1 $2)

# 将结果写入文件
echo "$rec" >> /tmp/result.at