## StrongSwan 一键安装脚本

clone 项目到任意位置，进入项目目录执行 `./install.sh your_host eth0` 稍等片刻即可

安装过程中会自动创建证书，提示输入密码等；默认安装在 `/usr/local/strongswan` 目录

配置文件在 `/usr/local/strongswan/etc` 目录，默认会创建用户名为 `mritd` 的账户，

密码随机生成；密码文件位于 `/usr/local/strongswan/etc/ipsec.secrets` 请自行添加修改


## vpn 支持

目前测试支持 windows7、windows10、ios9+、mac10.11.6+ 设备，理论支持安卓(手里没有)；

windows 系统需要导入 p12 证书，并把 CA 加入到系统受信任根证书中，方法自行谷歌；

windows7 连接 IKEV2 验证方式选择证书方式，windows10 bug 不断，创建 vpn 时请选择自动；

如果 vpn 服务器位于内网代理服务器之内，则 mac 和 ios 设备连接时 远程 ID 为内网主机的

内网 IP，可自行更改 `/usr/local/strongswan/etc/ipsec.conf` 配置文件自定义连接需求；

默认安装后写入 systemd service 文件，即通过 systemctl 启动停止等，具体自行 google.

