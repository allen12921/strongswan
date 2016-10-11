## StrongSwan 一键安装脚本


### 1、安装主程序

clone 项目到任意位置，进入项目目录执行 `./install.sh` 稍等片刻即可

### 2、初始化用户

安装完主程序后，将会 cp 目录下的 `vpnctl` 到 `/usr/local/bin/vpnctl` 位置，如果该位置位于
环境变量中，那么在任意位置执行 `vpnctl init` 即可，然后按照提示依次输入 用户名、密码、PSK

### 3、其他操作

- vpnctl: 该命令支持 `start | restart | stop | init` 四个选项
- vpn_adduser: `vpn_adduser USERNAME PASSWD` 增加新用户
- vpn_deluser: `vpn_deluser USERNAME` 删除用户
- vpn_setpsk: `vpn_setpsk PSK` 设置 PSK
- vpn_unsetpsk: `vpn_unsetpsk PSK` 撤销 PSK
