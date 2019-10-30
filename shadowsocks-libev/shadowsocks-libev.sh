#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#====================================#
#   系统要求:CentOS 6,CentOS 7       #
#   描述:安装Shadowsocks-libev服务   #
#====================================#

#需要的文件
# libsodium.tar.gz #下载:https://github.com/jedisct1/libsodium/releases
# mbedtls.tgz #下载:https://tls.mbed.org/download-archive（GPL）
# shadowsocks_libev.tar.gz #下载:https://github.com/shadowsocks/shadowsocks-libev/tags
# shadowsocks-libev #下载:https://github.com/teddysun/shadowsocks_install/blob/master/shadowsocks-libev

#获取当前目录路径#
cur_dir=$(pwd)

# Stream Ciphers
ciphers=(
aes-256-gcm
aes-192-gcm
aes-128-gcm
aes-256-ctr
aes-192-ctr
aes-128-ctr
aes-256-cfb
aes-192-cfb
aes-128-cfb
camellia-128-cfb
camellia-192-cfb
camellia-256-cfb
xchacha20-ietf-poly1305
chacha20-ietf-poly1305
chacha20-ietf
chacha20
salsa20
rc4-md5
)
# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

print_info(){
    clear
    echo "##################################################"
    echo "#                                                #"
    echo "#               Shadowsocks-libev                #"
    echo "#                                                #"
    echo "##################################################"
    echo
}

# Check system
check_sys(){
    local checkType=$1
    local value=$2
    local release=''
    local systemPackage=''
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

check_installed(){
    if [ "$(command -v "$1")" ]; then
        return 0
    else
        return 1
    fi
}

# Pre-installation settings
pre_install(){
    # Check OS system
    if check_sys sysRelease centos; then
        # Not support CentOS 5
        if centosversion 5; then
            echo -e "[${red}Error${plain}] 不支持CentOS 5,请更改为CentOS 6,CentOS 7."
            exit 1
        fi
    else
        echo -e "[${red}Error${plain}] 不支持本系统安装,请更改为CentOS 6,CentOS 7."
        exit 1
    fi
	
    # 检查是否安装shadowsocks-libev
	check_installed "ss-server"
    status=$?
    if [ ${status} -eq 0 ]; then
        echo -e "shadowsocks-libev已安装！"
        exit 0
    fi
	
    # Set shadowsocks-libev config password
	echo "shadowsocks-libev"
    echo "请输入密码:"
    read -p "(默认密码:xiyangdiy):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="xiyangdiy"
    echo
    echo "---------------------------"
    echo "密码:${shadowsockspwd}"
    echo "---------------------------"
    echo

    # Set shadowsocks-libev config port
    while true
    do
    dport=$(shuf -i 9000-19999 -n 1)
    echo -e "请设置端口[1-65535]"
    read -p "(默认端口:${dport}):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport=${dport}
    expr ${shadowsocksport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ] && [ ${shadowsocksport:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "端口:${shadowsocksport}"
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}]请输入正确的端口[1-65535]"
    done

    # Set shadowsocks config stream ciphers
    while true
    do
    echo -e "请选择加密方式:"
    for ((i=1;i<=${#ciphers[@]};i++ )); do
        hint="${ciphers[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "(默认:${ciphers[0]}):" pick
    [ -z "$pick" ] && pick=1
    expr ${pick} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] 请输入数字"
        continue
    fi
    if [[ "$pick" -lt 1 || "$pick" -gt ${#ciphers[@]} ]]; then
        echo -e "[${red}Error${plain}]请输入1~${#ciphers[@]}之间的数字"
        continue
    fi
    shadowsockscipher=${ciphers[$pick-1]}
    echo
    echo "---------------------------"
    echo "加密方式:${shadowsockscipher}"
    echo "---------------------------"
    echo
    break
    done

    echo
    echo "请按任意键继续...或者按Ctrl+C取消"
    char=`get_char`
    #Install necessary dependencies
    echo -e "[${green}Info${plain}] 正在校验EPEL存储库..."
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
        yum install -y -q epel-release
    fi
    [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] 安装EPEL存储库失败, 请检查." && exit 1
    [ ! "$(command -v yum-config-manager)" ] && yum install -y -q yum-utils
    if [ x"`yum-config-manager epel | grep -w enabled | awk '{print $3}'`" != x"True" ]; then
        yum-config-manager --enable epel
    fi
    echo -e "[${green}Info${plain}] 校验EPEL存储库完成..."
    yum install -y -q unzip openssl openssl-devel gettext gcc autoconf libtool automake make asciidoc xmlto libev-devel pcre pcre-devel git c-ares-devel
}

#安装libsodium#
install_libsodium() {
    wget https://raw.githubusercontent.com/xiyangdiy/shadowsocks/master/shadowsocks-libev/libsodium-1.0.17.tar.gz
    var=$(find ${cur_dir} -name 'libsodium*')
    libsodium_file=$(basename $var .tar.gz)
    if [ ! -f /usr/lib/libsodium.a ]; then
        cd ${cur_dir}
        tar zxf ${libsodium_file}.tar.gz
        cd ${libsodium_file}
        ./configure --prefix=/usr && make && make install
        if [ $? -ne 0 ]; then
		    cd ${cur_dir}
            rm -rf ${libsodium_file} ${libsodium_file}.tar.gz
            echo -e "[${red}Error${plain}] ${libsodium_file} 安装失败！"
			remove
            exit 1
        fi
    else
	    cd ${cur_dir}
        rm -rf ${libsodium_file} ${libsodium_file}.tar.gz
        echo -e "[${green}Info${plain}] ${libsodium_file} 安装完成！"
    fi
}

#安装mbedtls#
install_mbedtls() {
    wget https://github.com/xiyangdiy/shadowsocks/raw/master/shadowsocks-libev/mbedtls-2.16.0-gpl.tgz
	var=$(find ${cur_dir} -name 'mbedtls*')
    mbedtls_file=$(basename $var -gpl.tgz)
    if [ ! -f /usr/lib/libmbedtls.a ]; then
        cd ${cur_dir}
        tar xf ${mbedtls_file}-gpl.tgz
        cd ${mbedtls_file}
        make SHARED=1 CFLAGS=-fPIC
        make DESTDIR=/usr install
        if [ $? -ne 0 ]; then
		    cd ${cur_dir}
            rm -rf ${mbedtls_file} ${mbedtls_file}-gpl.tgz
            echo -e "[${red}Error${plain}] ${mbedtls_file} 安装失败！"
			remove
            exit 1
        fi
    else
	    cd ${cur_dir}
        rm -rf ${mbedtls_file} ${mbedtls_file}-gpl.tgz
        echo -e "[${green}Info${plain}] ${mbedtls_file} 安装完成！"
    fi
}

# Config shadowsocks
config_shadowsocks(){
    local server_value="\"0.0.0.0\""
    if get_ipv6; then
        server_value="[\"[::0]\",\"0.0.0.0\"]"
    fi

    if check_kernel_version && check_kernel_headers; then
        fast_open="true"
    else
        fast_open="false"
    fi

    if [ ! -d /etc/shadowsocks-libev ]; then
        mkdir -p /etc/shadowsocks-libev
    fi
    cat > /etc/shadowsocks-libev/config.json<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "password":"${shadowsockspwd}",
    "timeout":300,
    "user":"nobody",
    "method":"${shadowsockscipher}",
    "fast_open":${fast_open},
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
EOF
}

# Firewall set
firewall_set(){
    echo -e "[${green}Info${plain}]启动防火墙..."
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i ${shadowsocksport} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksport} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo -e "[${green}Info${plain}]端口${shadowsocksport}已开启！"
            fi
        else
            echo -e "[${yellow}Warning${plain}]iptables似乎已经关闭或者没有安装,如果有必要请手动设置！"
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            default_zone=$(firewall-cmd --get-default-zone)
            firewall-cmd --permanent --zone=${default_zone} --add-port=${shadowsocksport}/tcp
            firewall-cmd --permanent --zone=${default_zone} --add-port=${shadowsocksport}/udp
            firewall-cmd --reload
        else
            echo -e "[${yellow}Warning${plain}] firewalld看起来没有运行或者没有安装, 如果有必要请手动打开${shadowsocksport}端口！"
        fi
    fi
    echo -e "[${green}Info${plain}] firewall已经完成设置..."
}

# Install Shadowsocks-libev
install_shadowsocks(){
    install_libsodium
    install_mbedtls
    wget https://github.com/xiyangdiy/shadowsocks/raw/master/shadowsocks-libev/shadowsocks-libev-3.2.5.tar.gz
	wget https://raw.githubusercontent.com/xiyangdiy/shadowsocks/master/shadowsocks-libev/shadowsocks-libev
	var=$(find ${cur_dir} -name 'shadowsocks-libev-*')
    shadowsocks_libev_ver=$(basename $var .tar.gz)
    mv ${cur_dir}/shadowsocks-libev /etc/init.d/shadowsocks	
    ldconfig
    cd ${cur_dir}
    tar zxf ${shadowsocks_libev_ver}.tar.gz
    cd ${shadowsocks_libev_ver}
    ./configure --disable-documentation
    make && make install
    if [ $? -eq 0 ]; then
        chmod +x /etc/init.d/shadowsocks
        chkconfig --add shadowsocks
        chkconfig shadowsocks on
        # Start shadowsocks
        /etc/init.d/shadowsocks start
        if [ $? -eq 0 ]; then
            cd ${cur_dir}
            rm -rf ${shadowsocks_libev_ver} ${shadowsocks_libev_ver}.tar.gz
			echo -e "[${green}Info${plain}] Shadowsocks-libev成功开启！"
        else
            cd ${cur_dir}
            rm -rf ${shadowsocks_libev_ver} ${shadowsocks_libev_ver}.tar.gz
			echo -e "[${yellow}Warning${plain}] Shadowsocks-libev开启失败！"
        fi
    else
	    cd ${cur_dir}
        rm -rf ${shadowsocks_libev_ver} ${shadowsocks_libev_ver}.tar.gz
        echo
        echo -e "[${red}Error${plain}] Shadowsocks-libev安装失败！"
		remove
        exit 1
    fi

    clear
    echo
    echo -e "Shadowsocks-libev安装完成:"
    echo -e "IP:\033[41;37m $(get_ip) \033[0m"
    echo -e "端口:\033[41;37m ${shadowsocksport} \033[0m"
    echo -e "密码:\033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "加密方式:\033[41;37m ${shadowsockscipher} \033[0m"
    echo
    echo
}


# Install Shadowsocks-libev
install_shadowsocks_libev(){
    print_info
    disable_selinux
    pre_install
    config_shadowsocks
    firewall_set
    install_shadowsocks
}

# Uninstall Shadowsocks-libev
uninstall_shadowsocks_libev(){
    clear
    print_info
    printf "是否卸载Shadowsocks-libev? (y/n)"
    printf "\n"
    read -p "(默认:n):" answer
    [ -z ${answer} ] && answer="n"

    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ps -ef | grep -v grep | grep -i "ss-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        chkconfig --del shadowsocks
        rm -fr /etc/shadowsocks-libev
        rm -f /usr/local/bin/ss-local
        rm -f /usr/local/bin/ss-tunnel
        rm -f /usr/local/bin/ss-server
        rm -f /usr/local/bin/ss-manager
        rm -f /usr/local/bin/ss-redir
        rm -f /usr/local/bin/ss-nat
        rm -f /usr/local/lib/libshadowsocks-libev.a
        rm -f /usr/local/lib/libshadowsocks-libev.la
        rm -f /usr/local/include/shadowsocks.h
        rm -f /usr/local/lib/pkgconfig/shadowsocks-libev.pc
        rm -f /usr/local/share/man/man1/ss-local.1
        rm -f /usr/local/share/man/man1/ss-tunnel.1
        rm -f /usr/local/share/man/man1/ss-server.1
        rm -f /usr/local/share/man/man1/ss-manager.1
        rm -f /usr/local/share/man/man1/ss-redir.1
        rm -f /usr/local/share/man/man1/ss-nat.1
        rm -f /usr/local/share/man/man8/shadowsocks-libev.8
        rm -fr /usr/local/share/doc/shadowsocks-libev
        rm -f /etc/init.d/shadowsocks
        echo "Shadowsocks-libev卸载完成！"
    else
        echo
        echo "已取消卸载！"
        echo
    fi
}

remove(){
        chkconfig --del shadowsocks
        rm -fr /etc/shadowsocks-libev
        rm -f /usr/local/bin/ss-local
        rm -f /usr/local/bin/ss-tunnel
        rm -f /usr/local/bin/ss-server
        rm -f /usr/local/bin/ss-manager
        rm -f /usr/local/bin/ss-redir
        rm -f /usr/local/bin/ss-nat
        rm -f /usr/local/lib/libshadowsocks-libev.a
        rm -f /usr/local/lib/libshadowsocks-libev.la
        rm -f /usr/local/include/shadowsocks.h
        rm -f /usr/local/lib/pkgconfig/shadowsocks-libev.pc
        rm -f /usr/local/share/man/man1/ss-local.1
        rm -f /usr/local/share/man/man1/ss-tunnel.1
        rm -f /usr/local/share/man/man1/ss-server.1
        rm -f /usr/local/share/man/man1/ss-manager.1
        rm -f /usr/local/share/man/man1/ss-redir.1
        rm -f /usr/local/share/man/man1/ss-nat.1
        rm -f /usr/local/share/man/man8/shadowsocks-libev.8
        rm -fr /usr/local/share/doc/shadowsocks-libev
        rm -f /etc/init.d/shadowsocks
        rm -rf ${shadowsocks_libev_ver} ${shadowsocks_libev_ver}.tar.gz
        rm -rf ${libsodium_file} ${libsodium_file}.tar.gz
        rm -rf ${mbedtls_file} ${mbedtls_file}-gpl.tgz
        echo "        已撤销安装！"   		
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
        ${action}_shadowsocks_libev
        ;;
    *)
        echo "参数错误! [${action}]"
        echo "用法: `basename $0` [install|uninstall]"
        ;;
esac
