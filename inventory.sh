#!/usr/bin/env bash
set -euo pipefail

function ip_for_mac() {
  local mac="$1"
  local ip

  if [[ -z "$mac" ]]; then
    echo "MAC address is required" >&2
    return 1
  fi

  ip=$(ip neigh | grep "$mac" | awk '{print $1}')

  if [[ -z "$ip" ]]; then
    echo "No IP found for MAC address $mac" >&2
    return 1
  fi

  echo "$ip"
}

function test() {
  jq -n '{ classroom: { hosts: { "l05-001": { ansible_user: "schule", ansible_host: "192.168.178.107", security_ssh_allowed_users: [ "schule", "L05" ] } } } }' | yq -pjson
}

function lab_machines() {
  while read -r -a line; do
    jq -n \
      --arg mac "${line[0]}" \
      --arg hostname "${line[1]}" \
      --arg ip "$(ip_for_mac "${line[0]}")" \
      '{ ($hostname): { ansible_user: "schule", ansible_host: $ip, security_ssh_allowed_users: [ "schule", "L05" ] } }'
  done <inventory-macs.txt | jq -s
}

function inventory() {
    lab_machines | jq -s '{ classroom: { hosts: .[] | add } }' | yq -pjson -o=yaml
}

inventory
