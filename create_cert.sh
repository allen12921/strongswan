#!/bin/bash

vpn_host=$1

rm -rf cert > /dev/null 2>&1
mkdir cert && cd cert

# create CA certificate
echo -e "\033[32mcreate CA certificate...\033[0m"
ipsec pki --gen --outform pem > ca.key.pem
ipsec pki --self --in ca.key.pem --dn "C=CN, O=StrongSwan, CN=StrongSwan CA" --ca --outform pem > ca.cert.pem

# create server certificate
echo -e "\033[32mcreate server certificate...\033[0m"
ipsec pki --gen --outform pem > server.key.pem
ipsec pki --pub --in server.key.pem | ipsec pki --issue --cacert ca.cert.pem \
  --cakey ca.key.pem --dn "C=CN, O=StrongSwan, CN=$vpn_host" \
  --san="$vpn_host" --san="`ifconfig |sed -n 2p|awk  '{ print $2 }'|tr -d 'addr:'`" --flag serverAuth --flag ikeIntermediate \
  --outform pem > server.cert.pem

# create client certificate
echo -e "\033[32mcreate client certificate...\033[0m"
ipsec pki --gen --outform pem > client.key.pem
ipsec pki --pub --in client.key.pem | ipsec pki --issue --cacert ca.cert.pem \
  --cakey ca.key.pem --dn "C=CN, O=StrongSwan, CN=Client" \
  --outform pem > client.cert.pem

# create pkcs12
echo -e "\033[32mcreate pkcs12 certificate...\033[0m"
openssl pkcs12 -export -inkey client.key.pem -in client.cert.pem -name "Client" \
  -certfile ca.cert.pem -caname "StrongSwan CA" -out client.cert.p12

# install certificate
echo -e "\033[33mremove old certificate...\033[0m"
rm -f /etc/ipsec.d/cacerts/ca.cert.pem > /dev/null 2>&1
rm -f /etc/ipsec.d/certs/server.cert.pem > /dev/null 2>&1
rm -f /etc/ipsec.d/private/server.key.pem > /dev/null 2>&1
rm -f /etc/ipsec.d/certs/client.cert.pem > /dev/null 2>&1
rm -f /etc/ipsec.d/private/client.key.pem > /dev/null 2>&1

cp -r ca.cert.pem /etc/ipsec.d/cacerts/
cp -r server.cert.pem /etc/ipsec.d/certs/
cp -r server.key.pem /etc/ipsec.d/private/
cp -r client.cert.pem /etc/ipsec.d/certs/
cp -r client.key.pem /etc/ipsec.d/private/
