#!/bin/bash

# Install soft
yum install -y gmp-devel xl2tpd module-init-tools gcc openssl-devel

# Delete old files
rm -rf /tmp/strongswan* > /dev/null 2>&1

# Download StrongSwan
wget https://download.strongswan.org/strongswan-5.5.0.tar.gz -O /tmp/strongswan-5.5.0.tar.gz

# Install StrongSwan
(cd /tmp && tar -zxvf strongswan-5.5.0.tar.gz )
(cd /tmp/strongswan-5.5.0 && \
./configure --prefix=/usr --sysconfdir=/etc \
		--enable-eap-radius \
		--enable-eap-mschapv2 \
		--enable-eap-identity \
		--enable-eap-md5 \
		--enable-eap-mschapv2 \
		--enable-eap-tls \
		--enable-eap-ttls \
		--enable-eap-peap \
		--enable-eap-tnc \
		--enable-eap-dynamic \
		--enable-xauth-eap \
		--enable-openssl \
	&& make -j \
	&& make install)

# Strongswan Configuration
cp ipsec.conf /etc/ipsec.conf
cp strongswan.conf /etc/strongswan.conf

# XL2TPD Configuration
cp xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
cp options.xl2tpd /etc/ppp/options.xl2tpd

# VPN Bin
cp vpnctl /usr/local/bin/vpnctl
cp vpn_adduser /usr/local/bin/vpn_adduser
cp vpn_deluser /usr/local/bin/vpn_deluser
cp vpn_setpsk /usr/local/bin/vpn_setpsk
cp vpn_unsetpsk /usr/local/bin/vpn_unsetpsk
cp vpn_apply /usr/local/bin/vpn_apply

# Delete tmp files
rm -rf /tmp/strongswan* > /dev/null 2>&1
