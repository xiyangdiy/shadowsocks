系统：CentOS 6+

下载：wget https://raw.githubusercontent.com/xiyangdiy/shadowsocks/master/shadowsocks-libev/shadowsocks-libev.tar.gz

解压：tar zxf shadowsocks-libev.tar.gz && cd shadowsocks-libev

安装：chmod +x shadowsocks-libev.sh &&  ./shadowsocks-libev.sh

卸载：cd /root && ./shadowsocks-libev.sh uninstall

启动：/etc/init.d/shadowsocks start

停止：/etc/init.d/shadowsocks stop

重启：/etc/init.d/shadowsocks restart

查看状态：/etc/init.d/shadowsocks status