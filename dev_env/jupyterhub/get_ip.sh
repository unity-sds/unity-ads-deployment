#!/bin/bash
set -e
IP=$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')
jq -n --arg ip "$IP" '{"ip":$ip}'
