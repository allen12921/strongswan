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

# Delete tmp files
rm -rf /tmp/strongswan* > /dev/null 2>&1

# Kernel、Iptables setting
sysctl -w net.ipv4.conf.all.rp_filter=2
iptables --table nat --append POSTROUTING --jump MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
for each in /proc/sys/net/ipv4/conf/*; do
	echo 0 > $each/accept_redirects
	echo 0 > $each/send_redirects
done

# Strongswan Configuration
mkdir -p $CONFIGPATH
cp ipsec.conf $CONFIGPATH/ipsec.conf
cp strongswan.conf $CONFIGPATH/strongswan.conf

# Generate a random password
P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
VPN_PASSWORD="$P1$P2$P3"

# Generate a random password
P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
VPN_PSK="$P1$P2$P3"

cat > $CONFIGPATH/ipsec.secrets <<EOF
# This file holds shared secrets or RSA private keys for authentication.
# RSA private key for this host, authenticating it to any other host
# which knows the public part.  Suitable public keys, for ipsec.conf, DNS,
# or configuration of other implementations, can be extracted conveniently
# with "ipsec showhostkey".

: RSA server.key.pem
: PSK "$VPN_PSK"

mritd : EAP "$VPN_PASSWORD"
mritd : XAUTH "$VPN_PASSWORD"
EOF
