#!/usr/bin/env bash
domain="test3.am1z.xyz"
eccPath=`find ~/.acme.sh -name "${domain}_ecc"|head -1`
mkdir -p /tmp/tls
touch /tmp/tls/tls.log
touch /tmp/tls/acme.log
if [[ ! -z ${eccPath} ]]
then
    modifyTime=`stat ${eccPath}/${domain}.key|sed -n '6,6p'|awk '{print $2" "$3" "$4" "$5}'`
    modifyTime=`date +%s -d "${modifyTime}"`
    currentTime=`date +%s`
    stampDiff=`expr ${currentTime} - ${modifyTime}`
    minutes=`expr ${stampDiff} / 60`
    status="normal"
    reloadTime="None for the time being"
    if [[ ! -z ${modifyTime} ]] && [[ ! -z ${currentTime} ]] && [[ ! -z ${stampDiff} ]] && [[ ! -z ${minutes} ]] && [[ ${minutes} -lt '120' ]]
    then
        nginx -s stop
        ~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath /etc/nginx/v2ray-agent-https/${domain}.crt --keypath /etc/nginx/v2ray-agent-https/${domain}.key --ecc >> /tmp/tls/acme.log
        nginx
        reloadTime=`date -d @${currentTime} +"%F %H:%M:%S"`
    fi
    echo "domain name：${domain}，modifyTime:"`date -d @${modifyTime} +"%F %H:%M:%S"`,"检查时间:"`date -d @${currentTime} +"%F %H:%M:%S"`,"The last time the certificate was generated:"`expr ${minutes} / 1440`"Days ago","Certificate status："${status},"Re -generate date："${reloadTime} >> /tmp/tls/tls.log
else
    echo 'Can't find the certificate path' >> /tmp/tls/tls.log
fi
