#!/bin/bash

INSTALLDIR="/usr/local/strongswan"
CONFIGPATH="$INSTALLDIR/etc"
PATH="$INSTALLDIR/bin:$INSTALLDIR/sbin:$PATH"
VPNHOST=$1
INTERFACE=$2

if [ ! -n $VPNHOST ]; then
	echo -e "033\31mError: VPNHOST is blank!\033[0m"
	echo -e "033\33m33mExample: $0 vpn.mritd.me [eth0]\033[0m"
	exit 1
fi

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