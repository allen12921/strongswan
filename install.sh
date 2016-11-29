#!/bin/bash

VERSION='5.5.1'
CONFIGPATH='/etc/strongswan'
INSTALLDIR='/usr/local/strongswan'

# Install soft
yum install -y gmp-devel pam-devel module-init-tools gcc make openssl-devel wget

# Delete old files
rm -rf /tmp/strongswan* > /dev/null 2>&1

# Download StrongSwan
wget https://download.strongswan.org/strongswan-$VERSION.tar.gz -O /tmp/strongswan-$VERSION.tar.gz

# Install StrongSwan
(cd /tmp && tar -zxvf strongswan-$VERSION.tar.gz )
(cd /tmp/strongswan-$VERSION && \
./configure --prefix=$CONFIGPATH \
            --sysconfdir=$CONFIGPATH \
            --enable-eap-identity \
						--enable-eap-md5 \
            --enable-eap-tnc \
						--enable-eap-dynamic \
						--enable-eap-radius \
						--enable-xauth-eap \
            --enable-xauth-pam \
						--enable-dhcp \
						--enable-openssl \
						--enable-addrblock \
						--enable-unity \
            --enable-certexpire \
						--enable-radattr \
						--enable-swanctl \
						--enable-openssl \
						--disable-gmp \
&& make -j \
&& make install)

mkdir -p /etc/{strongswan,xl2tpd,ppp}

# Strongswan Configuration
cp ipsec.conf $CONFIGPATH/ipsec.conf
cp strongswan.conf $CONFIGPATH/strongswan.conf

# VPN Bin
cp vpnctl /usr/local/bin/vpnctl
cp vpn_adduser /usr/local/bin/vpn_adduser
cp vpn_deluser /usr/local/bin/vpn_deluser
cp vpn_setpsk /usr/local/bin/vpn_setpsk
cp vpn_unsetpsk /usr/local/bin/vpn_unsetpsk

# Delete tmp files
rm -rf /tmp/strongswan* > /dev/null 2>&1
