#!/bin/bash

vpn_host=$1

mkdir cert && cd cert

# create CA certificate
ipsec pki --gen --outform pem > ca.key.pem
ipsec pki --self --in ca.key.pem --dn "C=CN, O=StrongSwan, CN=StrongSwan CA" --ca --outform pem > ca.cert.pem

# create server certificate
ipsec pki --gen --outform pem > server.key.pem
ipsec pki --pub --in server.key.pem | ipsec pki --issue --cacert ca.cert.pem \
--cakey ca.key.pem --dn "C=CN, O=StrongSwan, CN=$vpn_host" \
--san="$vpn_host" --flag serverAuth --flag ikeIntermediate \
--outform pem > server.cert.pem

# create client certificate
ipsec pki --gen --outform pem > client.key.pem
ipsec pki --pub --in client.key.pem | ipsec pki --issue --cacert ca.cert.pem \
--cakey ca.key.pem --dn "C=CN, O=StrongSwan, CN=Client" \
--outform pem > client.cert.pem

# create pkcs12
openssl pkcs12 -export -inkey client.key.pem -in client.cert.pem -name "Client" \
-certfile ca.cert.pem -caname "StrongSwan CA" -out client.cert.p12

# install certificate
cp -r ca.cert.pem /etc/ipsec.d/cacerts/
cp -r server.cert.pem /etc/ipsec.d/certs/
cp -r server.key.pem /etc/ipsec.d/private/
cp -r client.cert.pem /etc/ipsec.d/certs/
cp -r client.key.pem /etc/ipsec.d/private/
