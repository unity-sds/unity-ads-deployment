#!/bin/bash
IP=$(curl --connect-timeout 1 -s 'http://169.254.169.254/latest/meta-data/local-ipv4')
if [ "$IP" = "" ]; then
  IP=127.0.0.1
fi
echo "{\"ip\": \"${IP}\"}"
