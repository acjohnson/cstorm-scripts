#!/bin/bash
#

startTransmission () {
  QB_PID=$1

  if [ -z "${QB_PID}" ]; then
    echo "Transmission not running, starting..."
    systemctl start transmission-daemon
  else
    echo "Transmission is already running..."
  fi
}

stopTransmission () {
  QB_PID=$1

  if [ -z "${QB_PID}" ]; then
    echo "Transmission is already stopped..."
  else
    echo "Transmission is running, stopping..."
    systemctl stop transmission-daemon
  fi
}

startVPN () {
  VPN_STATE=$1

  if [ "${VPN_STATE}" == "active" ]; then
    echo "VPN is already running..."
    echo "Restarting VPN service to attempt to resolve DNS leak..."
    systemctl restart openvpn-client@cstorm.service
  else
    echo "VPN not running, starting..."
    systemctl start openvpn-client@cstorm.service
  fi
}

installNewToken () {
  TOKEN=$(/root/cstorm-scripts/imap-client.sh)
  echo "${TOKEN}" > /etc/openvpn/cstorm-creds-conf
  echo "thisisnotapassword" >> /etc/openvpn/cstorm-creds-conf
}

DATE_TIME="date"
START_DATE_TIME=$(eval "${DATE_TIME}")
echo "==== START VPN CHECK ===="
echo "${START_DATE_TIME}"

QB_PID_CMD="ps -ef | grep transmission-daemon | grep -v grep | awk '{print $2}'"
VPN_STATE_CMD="systemctl is-active openvpn-client@cstorm.service"
NS_CMD="grep -v ^# /etc/resolv.conf | grep ^nameserver | head -1 | awk '{print $2}'"

# Check to see if VPN is working
NS_CHECK_CMD="grep -v ^# /etc/resolv.conf | grep ^nameserver | head -1 | egrep '192\.168|127\.0' > /dev/null"
eval "${NS_CHECK_CMD}"

if [[ $? -ne 0 ]]; then
  NS=$(eval "${NS_CMD}")
  echo "Non-local nameserver detected: ${NS}, VPN appears to be working!"
  QB_PID=$(eval "${QB_PID_CMD}")
  startTransmission "${QB_PID}"
  echo "Exiting..."
else
  NS=$(eval "${NS_CMD}")
  echo "Local nameserver detected: ${NS}, VPN leak detected!"
  echo "Attempting to download and install the latest token!"
  installNewToken
  QB_PID=$(eval "${QB_PID_CMD}")
  stopTransmission "${QB_PID}"
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
    startTransmission "${QB_PID}"
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
