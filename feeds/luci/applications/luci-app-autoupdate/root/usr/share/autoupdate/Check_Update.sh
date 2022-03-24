#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001

rm -f /tmp/cloud_version
rm -f /tmp/Version_Tags
if [[ -f /bin/openwrt_info ]]; then
	chmod +x /bin/openwrt_info
	bash /bin/AutoUpdate.sh	-w
else
	echo "未检测到定时更新插件所需程序" > /tmp/cloud_version
	exit 1
fi
[[ ! -f /tmp/Version_Tags ]] && echo "未检测到云端版本,请检查网络,或您的仓库为私库,或您修改的Github地址有错误,或发布已被删除,或再次刷新网页试试!" > /tmp/cloud_version && exit 1
source /tmp/Version_Tags
chmod +x /tmp/Version_Tags
if [[ ! -z "${CLOUD_Version}" ]];then
	if [[ "${CURRENT_Version}" -eq "${CLOUD_Version}" ]];then
		Checked_Type="已是最新"
		echo "${CLOUD_Version} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -gt "${CLOUD_Version}" ]];then
		Checked_Type="发现更新"
		echo "${CLOUD_Version} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -lt "${CLOUD_Version}" ]];then
		Checked_Type="云端最高版本,低于您现在的版本"
		echo "${CLOUD_Version} [${Checked_Type}]" > /tmp/cloud_version	
	fi
else
	echo "没检测到云端固件，您可能把云端固件删除了，或格式不对称，比如爱快虚拟机安装EIF格式都会变成Legacy引导!" > /tmp/cloud_version
fi
exit 0
