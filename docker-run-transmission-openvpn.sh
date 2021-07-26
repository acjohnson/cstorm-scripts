#!/bin/bash -x

. /root/.transmission_creds.conf

/bin/docker kill transmission-openvpn
/bin/docker rm transmission-openvpn

/bin/docker run -d \
  --name transmission-openvpn \
  --cap-add NET_ADMIN \
  --restart unless-stopped \
  -v /library:/library \
  -v /docker/transmission/config:/data \
  -v /docker/transmission/default.ovpn:/etc/openvpn/custom/default.ovpn:ro \
  -e OPENVPN_OPTS="--inactive 3600 --ping 10 --ping-exit 60 --pull-filter ignore ping --pull-filter ignore ping-restart" \
  -e TRANSMISSION_DOWNLOAD_DIR="/library/Downloads" \
  -e TRANSMISSION_INCOMPLETE_DIR="/library/Downloads/incomplete" \
  -e TRANSMISSION_WATCH_DIR="/library/Downloads/watch" \
  -e TRANSMISSION_DOWNLOAD_QUEUE_SIZE="100" \
  -e TRANSMISSION_UTP_ENABLED=true \
  -e TRANSMISSION_PEER_LIMIT_GLOBAL="5000" \
  -e TRANSMISSION_PEER_LIMIT_PER_TORRENT="500" \
  -e LOG_TO_STDOUT=true \
  -e OPENVPN_PROVIDER=CUSTOM \
  -e OPENVPN_PASSWORD="${VPN_PASSWORD}" \
  -e OPENVPN_USERNAME="${VPN_TOKEN}" \
  -e LOCAL_NETWORK="192.168.0.0/16" \
  -e CREATE_TUN_DEVICE=true \
  -e DROP_DEFAULT_ROUTE=false \
  -e TZ="America/Chicago" \
  -e PUID=568 \
  -e PGID=568 \
  --log-driver json-file \
  --log-opt max-size=10m \
  -p 9091:9091 \
  haugene/transmission-openvpn:latest
