shadowsocks-libev
=================
安装服务
-------
系统：CentOS 6+

下载：wget https://raw.githubusercontent.com/xiyangdiy/shadowsocks/master/shadowsocks-libev/shadowsocks-libev.tar.gz

解压：tar zxf shadowsocks-libev.tar.gz

安装：chmod +x shadowsocks-libev.sh &&  ./shadowsocks-libev.sh

卸载：./shadowsocks-libev.sh uninstall

启动：/etc/init.d/shadowsocks start

停止：/etc/init.d/shadowsocks stop

重启：/etc/init.d/shadowsocks restart

查看状态：/etc/init.d/shadowsocks status

Google BBR魔改版加速
-------------------
(1)安装系统内核

wget --no-check-certificate https://raw.githubusercontent.com/nanqinlang-tcp/tcp_nanqinlang/master/General/CentOS/bash/tcp_nanqinlang-1.3.2.sh && bash tcp_nanqinlang-1.3.2.sh

选择:1

选择:y

重启:reboot

(2)开启算法

bash tcp_nanqinlang-1.3.2.sh

选择:2

选择:y
