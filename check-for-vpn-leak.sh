#!/bin/bash
#

startQbittorrent () {
  QB_PID=$1

  if [ -z "${QB_PID}" ]; then
    echo "Qbittorrent not running, starting..."
    systemctl start qbittorrent
  else
    echo "Qbittorrent is already running..."
  fi
}

stopQbittorrent () {
  QB_PID=$1

  if [ -z "${QB_PID}" ]; then
    echo "Qbittorrent is already stopped..."
  else
    echo "Qbittorrent is running, stopping..."
    systemctl stop qbittorrent
  fi
}

startVPN () {
  VPN_STATE=$1

  if [ "${VPN_STATE}" == "active" ]; then
    echo "VPN is already running..."
  else
    echo "VPN not running, starting..."
    systemctl start openvpn@cstorm.service
  fi
}

installNewToken () {
  TOKEN=$(/opt/cstorm-scripts/imap-client.sh)
  echo "${TOKEN}" > /etc/openvpn/cstorm-creds-conf
  echo "thisisnotapassword" >> /etc/openvpn/cstorm-creds-conf
}

DATE_TIME="date"
START_DATE_TIME=$(eval "${DATE_TIME}")
echo "==== START VPN CHECK ===="
echo "${START_DATE_TIME}"

QB_PID_CMD="ps -ef | grep qbittorrent | grep -v grep | awk '{print $2}'"
VPN_STATE_CMD="systemctl is-active openvpn@cstorm.service"
NS_CMD="grep -v ^# /etc/resolv.conf | grep ^nameserver | head -1 | awk '{print $2}'"

# Check to see if VPN is working
NS_CHECK_CMD="grep -v ^# /etc/resolv.conf | grep ^nameserver | head -1 | grep 192.168 > /dev/null"
eval "${NS_CHECK_CMD}"

if [[ $? -ne 0 ]]; then
  NS=$(eval "${NS_CMD}")
  echo "Non-local nameserver detected: ${NS}, VPN appears to be working!"
  QB_PID=$(eval "${QB_PID_CMD}")
  startQbittorrent "${QB_PID}"
  echo "Exiting..."
else
  NS=$(eval "${NS_CMD}")
  echo "Local nameserver detected: ${NS}, VPN leak detected!"
  echo "Attempting to download and install the latest token!"
  installNewToken
  QB_PID=$(eval "${QB_PID_CMD}")
  stopQbittorrent "${QB_PID}"
  echo "Attempting to start VPN..."
  VPN_STATE=$(eval "${VPN_STATE_CMD}")
  startVPN "${VPN_STATE}"
  echo "sleeping for 30 seconds"
  sleep 30
  eval "${NS_CHECK_CMD}"
  if [[ $? -ne 0 ]]; then
    NS=$(eval "${NS_CMD}")
    echo "Non-local nameserver detected: ${NS}, VPN leak fixed!"
    QB_PID=$(eval "${QB_PID_CMD}")
    startQbittorrent "${QB_PID}"
    echo "Exiting..."
  else
    NS=$(eval "${NS_CMD}")
    echo "Local nameserver still detected: ${NS}, giving up..."
    echo "Exiting..."
  fi
fi

END_DATE_TIME=$(eval "${DATE_TIME}")
echo "${END_DATE_TIME}"
echo "==== END VPN CHECK ===="
echo ''
