#!/bin/bash

systemctl stop strongswan
rm -rf /usr/local/strongswan
rm -f /usr/lib/systemd/system/strongswan.service
systemctl daemon-reload
