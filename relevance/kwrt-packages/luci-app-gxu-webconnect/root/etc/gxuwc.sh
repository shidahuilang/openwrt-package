enable=$(uci get gxu-webconnect.@gxu-webconnect[0].enable)
ID=$(uci get gxu-webconnect.@gxu-webconnect[0].id)              #获取输入的账号
PASSWORD=$(uci get gxu-webconnect.@gxu-webconnect[0].password)  #获取输入的密码
WEB_PROVIDER=$(uci get gxu-webconnect.@gxu-webconnect[0].web_provier)
delay=$(uci get gxu-webconnect.@gxu-webconnect[0].delay)
state=1

#根据插件页面运营商选项，赋值运营商代码，每个学校的登录系统不太相同，请自行设置
#校园网
if [ $WEB_PROVIDER = "0" ];then
    WEB_PROVIDER=""  
#移动   
elif [ $WEB_PROVIDER = "1" ];then
    WEB_PROVIDER="cmcc"
#联通
elif [ $WEB_PROVIDER = "2" ];then
    WEB_PROVIDER="unicom"
#电信
elif [ $WEB_PROVIDER = "3" ];then
    WEB_PROVIDER="telecom"
fi

Login()#登录函数，先注销等5s后再登录
{
    wget -qO- "http://172.17.0.2:801/eportal/?c=ACSetting&a=Logout&wlanacip=210.36.18.65" &> /dev/null #注销命令
    sleep 5
    wget -qO- "http://172.17.0.2:801/eportal/?c=ACSetting&a=Login&wlanacip=210.36.18.65&DDDDD=,0,${ID}@${WEB_PROVIDER}&upass=${PASSWORD}" &> /dev/null #登录命令
}

Loop()#循环检测网络状态
{
    #只在启用脚本时候运行循环
    while [ $enable = "1" ];do
        #测试网络通断，断网则尝试重新登录
        ping -c 3 -W 1 223.5.5.5 >/dev/null
        if [ $? != 0 ];then
            #若断网则向系统日志输出断网信息
            if [ $state -eq 1 ];then
                logger -t GXUwc "Network Down"  #断网信息
                state=0
            fi

            #尝试重登
            Login

            #重登后再次检测网络
            ping -c 3 -W 1 223.5.5.5 >/dev/null
            #若联网则向系统日志输出联网信息
            if [ $? = 0 ];then
                logger -t GXUwc "Network Up"    #联网信息
                state=1
            fi
        fi

        sleep $delay
        enable=$(uci get gxu-webconnect.@gxu-webconnect[0].enable)
    done
}

if [ $* = "Login" ];then
    Login
elif [ $* = "Loop" ];then
    Loop
fi