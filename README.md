## StrongSwan 一键安装脚本

clone 项目到任意位置，进入项目目录执行 `./install.sh your_host eth0` 稍等片刻即可

安装过程中会自动创建证书，提示输入密码等；默认安装在 `/usr/local/strongswan` 目录

配置文件在 `/usr/local/strongswan/etc` 目录，默认会创建用户名为 `mritd` 的账户，

密码随机生成；密码文件位于 `/usr/local/strongswan/etc/ipsec.secrets` 请自行添加修改


