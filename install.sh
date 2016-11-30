#!/bin/bash

VERSION="5.5.1"
INSTALLDIR="/usr/local/strongswan"
CONFIGPATH="$INSTALLDIR/etc"
PATH="$INSTALLDIR/bin:$INSTALLDIR/sbin:$PATH"

if [ ! -n "$1" ] || [ ! -n "$2" ]; then
    echo -e "\033[31mError: VPNHOST or INTERFACE is blank!\033[0m"
    echo -e "\033[33mExample: $0 vpn.mritd.me eth0\033[0m"
    exit 1
fi

VPNHOST=$1
INTERFACE=$2
IPADDRESS=`ifconfig $INTERFACE|sed -n 2p|awk  '{ print $2 }'|tr -d 'addr:'`

function install() {
    _preinstall
    _install
    _postinstall
    config_iptables
    config_kernel
    config_strongswan
    create_cert
}

function _preinstall() {
    # Install soft
    yum install -y gmp-devel pam-devel module-init-tools gcc make openssl-devel wget
    # Delete old files
    rm -rf /tmp/strongswan* > /dev/null 2>&1
    # Download StrongSwan
    wget https://download.strongswan.org/strongswan-$VERSION.tar.gz -O /tmp/strongswan-$VERSION.tar.gz
    # Install StrongSwan
    (cd /tmp && tar -zxvf strongswan-$VERSION.tar.gz )
}

function _install() {
    (cd /tmp/strongswan-$VERSION && \
    ./configure --prefix=$INSTALLDIR \
                --sysconfdir=$CONFIGPATH \
                --enable-eap-identity \
                --enable-eap-md5 \
                --enable-eap-mschapv2 \
                --enable-eap-tls \
                --enable-eap-ttls \
                --enable-eap-peap \
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
}

function _postinstall() {
    # Delete tmp files
    rm -rf /tmp/strongswan* > /dev/null 2>&1
}

function config_iptables() {
    # Iptables setting
    iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -s 10.31.0.0/24  -j ACCEPT
    iptables -A FORWARD -s 10.31.1.0/24  -j ACCEPT
    iptables -A FORWARD -s 10.31.2.0/24  -j ACCEPT
    iptables -A INPUT -i $INTERFACE -p esp -j ACCEPT
    iptables -A INPUT -i $INTERFACE -p udp --dport 500 -j ACCEPT
    iptables -A INPUT -i $INTERFACE -p tcp --dport 500 -j ACCEPT
    iptables -A INPUT -i $INTERFACE -p udp --dport 4500 -j ACCEPT
    iptables -A INPUT -i $INTERFACE -p udp --dport 1701 -j ACCEPT
    iptables -A INPUT -i $INTERFACE -p tcp --dport 1723 -j ACCEPT
    iptables -t nat -A POSTROUTING -s 10.31.0.0/24 -o $INTERFACE -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 10.31.1.0/24 -o $INTERFACE -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 10.31.2.0/24 -o $INTERFACE -j MASQUERADE
}

function config_kernel() {
    sysctl -w net.ipv4.conf.all.rp_filter=2
    echo 1 > /proc/sys/net/ipv4/ip_forward
    for each in /proc/sys/net/ipv4/conf/*; do
        echo 0 > $each/accept_redirects
        echo 0 > $each/send_redirects
    done
}


function config_strongswan() {
    # Strongswan Configuration
    mkdir -p $CONFIGPATH 

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

    cat > $CONFIGPATH/ipsec.conf <<EOF
config setup
    uniqueids=never

conn iOS_cert
    keyexchange=ikev1
    fragmentation=yes
    left=%defaultroute
    leftauth=pubkey
    leftsubnet=0.0.0.0/0
    leftcert=server.cert.pem
    right=%any
    rightauth=pubkey
    rightauth2=xauth
    rightsourceip=10.31.2.0/24
    rightcert=client.cert.pem
    auto=add

conn android_xauth_psk
    keyexchange=ikev1
    left=%defaultroute
    leftauth=psk
    leftsubnet=0.0.0.0/0
    right=%any
    rightauth=psk
    rightauth2=xauth
    rightsourceip=10.31.2.0/24
    auto=add

conn networkmanager-strongswan
    keyexchange=ikev2
    left=%defaultroute
    leftauth=pubkey
    leftsubnet=0.0.0.0/0
    leftcert=server.cert.pem
    right=%any
    rightauth=pubkey
    rightsourceip=10.31.2.0/24
    rightcert=client.cert.pem
    auto=add

conn ios_ikev2
    keyexchange=ikev2
    ike=aes256-sha256-modp2048,3des-sha1-modp2048,aes256-sha1-modp2048!
    esp=aes256-sha256,3des-sha1,aes256-sha1!
    rekey=no
    left=%defaultroute
    leftid=$IPADDRESS
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    leftcert=server.cert.pem
    right=%any
    rightauth=eap-mschapv2
    rightsourceip=10.31.2.0/24
    rightsendcert=never
    eap_identity=%any
    dpdaction=clear
    fragmentation=yes
    auto=add

conn windows7
    keyexchange=ikev2
    ike=aes256-sha1-modp1024!
    rekey=no
    left=%defaultroute
    leftauth=pubkey
    leftsubnet=0.0.0.0/0
    leftcert=server.cert.pem
    right=%any
    rightauth=eap-mschapv2
    rightsourceip=10.31.2.0/24
    rightsendcert=never
    eap_identity=%any
    auto=add

EOF

    cat > $CONFIGPATH/strongswan.conf <<EOF
# /etc/strongswan.conf - strongSwan configuration file
# strongswan.conf - strongSwan configuration file
#
# Refer to the strongswan.conf(5) manpage for details

charon {
    load_modular = yes
    duplicheck.enable = no
    compress = yes
    plugins {
        include strongswan.d/charon/*.conf
    }
    dns1 = 8.8.8.8
    dns2 = 8.8.4.4
    nbns1 = 8.8.8.8
    nbns2 = 8.8.4.4
}
include strongswan.d/*.conf
EOF

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
}

function create_cert(){

    # remove old files
    rm -rf cert > /dev/null 2>&1
    mkdir cert && cd cert

    # create CA certificate
    echo -e "\033[32mCreate CA certificate...\033[0m"
    ipsec pki --gen --outform pem > ca.key.pem
    ipsec pki --self --in ca.key.pem --dn "C=CN, O=StrongSwan, CN=StrongSwan CA" --ca --outform pem > ca.cert.pem

    # create server certificate
    echo -e "\033[32mCreate server certificate...\033[0m"
    ipsec pki --gen --outform pem > server.key.pem
    ipsec pki --pub --in server.key.pem | ipsec pki --issue --cacert ca.cert.pem \
      --cakey ca.key.pem --dn "C=CN, O=StrongSwan, CN=$VPNHOST" \
      --san "$VPNHOST" --san="`ifconfig $INTERFACE|sed -n 2p|awk  '{ print $2 }'|tr -d 'addr:'`" --flag serverAuth --flag ikeIntermediate \
      --outform pem > server.cert.pem

    # create client certificate
    echo -e "\033[32mCreate client certificate...\033[0m"
    ipsec pki --gen --outform pem > client.key.pem
    ipsec pki --pub --in client.key.pem | ipsec pki --issue --cacert ca.cert.pem \
      --cakey ca.key.pem --dn "C=CN, O=StrongSwan, CN=Client" \
      --outform pem > client.cert.pem

    # create pkcs12
    echo -e "\033[32mCreate pkcs12 certificate...\033[0m"
    openssl pkcs12 -export -inkey client.key.pem -in client.cert.pem -name "Client" \
      -certfile ca.cert.pem -caname "StrongSwan CA" -out client.cert.p12

    # install certificate
    echo -e "\033[33mremove old certificate...\033[0m"
    rm -f $CONFIGPATH/ipsec.d/cacerts/ca.cert.pem > /dev/null 2>&1
    rm -f $CONFIGPATH/ipsec.d/certs/server.cert.pem > /dev/null 2>&1
    rm -f $CONFIGPATH/ipsec.d/private/server.key.pem > /dev/null 2>&1
    rm -f $CONFIGPATH/ipsec.d/certs/client.cert.pem > /dev/null 2>&1
    rm -f $CONFIGPATH/ipsec.d/private/client.key.pem > /dev/null 2>&1

    echo -e "\033[32mInstall certificate...\033[0m"
    cp -r ca.cert.pem $CONFIGPATH/ipsec.d/cacerts/
    cp -r server.cert.pem $CONFIGPATH/ipsec.d/certs/
    cp -r server.key.pem $CONFIGPATH/ipsec.d/private/
    cp -r client.cert.pem $CONFIGPATH/ipsec.d/certs/
    cp -r client.key.pem $CONFIGPATH/ipsec.d/private/
}

install
