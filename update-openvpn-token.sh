#!/bin/bash

/bin/docker exec transmission-openvpn pidof transmission-daemon

if [ $? == 0 ]; then
  echo "transmission is running, vpn presumably working..."
else
  echo "transmission is down, attempting to update VPN token..."
  TOKEN=$(/root/imap-client.sh)
  echo "export VPN_TOKEN=\"${TOKEN}\"" > /root/.transmission_creds.conf
  echo "export VPN_PASSWORD=\"thisisnotapassword\"" >> /root/.transmission_creds.conf
  /root/docker-run-transmission-openvpn.sh
fi
