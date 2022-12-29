#!/usr/bin/env bash
installType='yum -y install'
removeType='yum -y remove'
upgrade="yum -y update"
echoType='echo -e'
cp=`which cp`
# 打印
echoColor(){
    case $1 in
        # 红色
        "red")
            ${echoType} "\033[31m$2 \033[0m"
        ;;
        # 天蓝色
        "skyBlue")
            ${echoType} "\033[36m$2 \033[0m"
        ;;
        # 绿色
        "green")
            ${echoType} "\033[32m$2 \033[0m"
        ;;
        # 白色
        "white")
            ${echoType} "\033[37m$2 \033[0m"
        ;;
        "magenta")
            ${echoType} "\033[31m$2 \033[0m"
        ;;
        "skyBlue")
            ${echoType} "\033[36m$2 \033[0m"
        ;;
        # 黄色
        "yellow")
            ${echoType} "\033[33m$2 \033[0m"
        ;;
    esac
}
# 选择系统执行工具
checkSystem(){

	if [[ ! -z `find /etc -name "redhat-release"` ]] || [[ ! -z `cat /proc/version | grep -i "centos" | grep -v grep ` ]] || [[ ! -z `cat /proc/version | grep -i "red hat" | grep -v grep ` ]] || [[ ! -z `cat /proc/version | grep -i "redhat" | grep -v grep ` ]]
	then
		release="centos"
		installType='yum -y install'
		removeType='yum -y remove'
		upgrade="yum update -y"
	elif [[ ! -z `cat /etc/issue | grep -i "debian" | grep -v grep` ]] || [[ ! -z `cat /proc/version | grep -i "debian" | grep -v grep` ]]
    then
		release="debian"
		installType='apt -y install'
		upgrade="apt update -y"
		removeType='apt -y autoremove'
	elif [[ ! -z `cat /etc/issue | grep -i "ubuntu" | grep -v grep` ]] || [[ ! -z `cat /proc/version | grep -i "ubuntu" | grep -v grep` ]]
	then
		release="ubuntu"
		installType='apt -y install'
		upgrade="apt update -y"
		removeType='apt --purge remove'
    fi
    if [[ -z ${release} ]]
    then
        echoContent red "This script does not support this system, please give feedback to the developer below"
        cat /etc/issue
        cat /proc/version
        exit 0;
    fi
}
# 安装工具包
installTools(){
    echoColor yellow "renew"
    ${upgrade}
    if [[ -z `find /usr/bin/ -executable -name "socat"` ]]
    then
        echoColor yellow "\nsocat Not installed, installed\n"
        ${installType} socat >/dev/null
        echoColor green "socat installation is complete"
    fi
    echoColor yellow "\nDetect whether to install Nginx"
    if [[ -z `find /sbin/ -executable -name 'nginx'` ]]
    then
        echoColor yellow "nginx Not installed, installed\n"
        ${installType} nginx >/dev/null
        echoColor green "nginx Installed"
    else
        echoColor green "nginx Installed\n"
    fi
    echoColor yellow "Detect whether to install acme.sh"
    if [[ -z `find ~/.acme.sh/ -name "acme.sh"` ]]
    then
        echoColor yellow "\nacme.sh Not installed, installed\n"
        curl -s https://get.acme.sh | sh >/dev/null
        echoColor green "acme.sh Installed\n"
    else
        echoColor green "acme.sh Installed\n"
    fi

}
# 恢复配置
resetNginxConfig(){
    `cp -Rrf /tmp/mack-a/nginx/nginx.conf /etc/nginx/nginx.conf`
    rm -rf /etc/nginx/conf.d/5NX2O9XQKP.conf
    echoColor green "\n recovery configuration is complete"
}
# 备份
bakConfig(){
    mkdir -p /tmp/mack-a/nginx
    `cp -Rrf /etc/nginx/nginx.conf /tmp/mack-a/nginx/nginx.conf`
}
# 安装证书
installTLS(){
    echoColor yellow "Please enter the domain name [Example:blog.v2ray-agent.com】："
    read domain
    if [[ -z ${domain} ]]
    then
        echoColor red "Domain name is not filled in\n"
        installTLS
    fi
    # 备份
    bakConfig
    # 替换原始文件中的域名
    if [[ ! -z `cat /etc/nginx/nginx.conf|grep -v grep|grep "${domain}"` ]]
    then
        sed -i "s/${domain}/X655Y0M9UM9/g"  `grep "${domain}" -rl /etc/nginx/nginx.conf`
    fi

    touch /etc/nginx/conf.d/6GFV1ES52V2.conf
    echo "server {listen 80;server_name ${domain};root /usr/share/nginx/html;location ~ /.well-known {allow all;}location /test {return 200 '5NX2O9XQKP';}}" > /etc/nginx/conf.d/5NX2O9XQKP.conf
    nginxStatus=1;
    if [[ ! -z `ps -ef|grep -v grep|grep nginx` ]]
    then
        nginxStatus=2;
        ps -ef|grep -v grep|grep nginx|awk '{print $2}'|xargs kill -9
        sleep 0.5
        nginx
    else
        nginx
    fi
    echoColor yellow "\n Verify the domain name and whether the server is available"
    if [[ ! -z `curl -s ${domain}/test|grep 5NX2O9XQKP` ]]
    then
        ps -ef|grep -v grep|grep nginx|awk '{print $2}'|xargs kill -9
        sleep 0.5
        echoColor green "Service available, generate in TLS, please wait\n"
    else
        echoColor red "If the service is not available, please detect whether the DNS configuration is correct"
        # 恢复备份
        resetNginxConfig
        exit 0;
    fi
    sudo ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 >/dev/null
    ~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath /tmp/mack-a/nginx/${domain}.crt --keypath /tmp/mack-a/nginx/${domain}.key --ecc >/dev/null
    if [[ -z `cat /tmp/mack-a/nginx/${domain}.key` ]]
    then
        echoColor red "Certificate Key failed, please reorganize"
        resetNginxConfig
        exit
    elif [[ -z `cat /tmp/mack-a/nginx/${domain}.crt` ]]
    then
        echoColor red "Certificate CRT generating failure, please reorganize"
        resetNginxConfig
        exit
    fi
    echoColor green "Successful certificate"
    echoColor green "Certificate Directory /tmp/mack-a/nginx"
    ls /tmp/mack-a/nginx

    resetNginxConfig
    if [[ ${nginxStatus} = 2  ]]
    then
        nginx
    fi
}

init(){
    echoColor red "\n=============================="
    echoColor yellow "Precautions for this script"
    echoColor green "   1.Will install dependencies that need dependencies"
    echoColor green "   2.Will back up nginx configuration files"
    echoColor green "   3.Will install nginx, acme.SH, if it is installed, use the existing existence"
    echoColor green "   4.After the installation or failure, the backup will be automatically restored, please do not turn off the script manually"
    echoColor green "   5.Please do not restart the machine during execution"
    echoColor green "   6.Backup documents and certificates are all here/tmp below, please pay attention to retain"
    echoColor green "   7.If it is executed multiple times, the last -time backup and generated certificates are forced to cover"
    echoColor green "   8.Certificate default ec-256"
    echoColor green "   9.The next version will be added with a formal symbol certificate to generate[todo]"
    echoColor green "   10.You can generate a certificate of multiple different domain names[Including sub -domain name]Please view the specific rate[https://letsencrypt.org/zh-cn/docs/rate-limits/]"
    echoColor green "   11.Compatible with CentOS, Ubuntu, Debian"
    echoColor green "   12.Github[https://github.com/mack-a]"
    echoColor red "=============================="
    echoColor yellow "Please enter [y] execute script, [enter] end:"
    read isExecStatus
    if [[ ${isExecStatus} = "y" ]]
    then
        installTools
        installTLS
    else
        echoColor green "Welcome to use next time"
        exit
    fi
}
checkSystem
init
