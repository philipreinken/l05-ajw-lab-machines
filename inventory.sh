#!/usr/bin/env bash
set -euo pipefail

function arp_scan() {
  if [ ! -f ".arp-cache" ]; then
    echo "Running arp-scan to populate .arp-cache file..." >&2
    sudo arp-scan --localnet | awk '/^[0-9]/ {print $1, $2}' | uniq | sort -u | tee .arp-cache
  else
    echo ".arp-cache file already exists, skipping arp-scan." >&2
  fi

  cat .arp-cache
}

function ip_for_mac() {
  local mac="$1"
  local ip

  if [[ -z "$mac" ]]; then
    echo "MAC address is required" >&2
    return 1
  fi

  ip=$(arp_scan | grep "$mac" | awk '{print $1}')

  if [[ -z "$ip" ]]; then
    echo "No IP found for MAC address $mac" >&2
    return
  fi

  echo "$ip"
}

function lab_machines() {
  while read -r -a line; do
    echo "Processing MAC: ${line[0]}, Hostname: ${line[1]}" >&2

    local host_ip; host_ip=$(ip_for_mac "${line[0]}")

    if [ -z "$host_ip" ]; then
      echo "Skipping ${line[1]} due to missing IP for MAC ${line[0]}" >&2
      continue
    fi

    jq -n \
      --arg mac "${line[0]}" \
      --arg hostname "${line[1]}" \
      --arg ip "${host_ip}" \
      '{ ($hostname): { ansible_user: "schule", ansible_host: $ip, security_ssh_allowed_users: [ "schule", "L05" ] } }'
  done <inventory-macs.txt | jq -s
}

function inventory() {
    lab_machines | jq -s '{ classroom: { hosts: .[] | add } }' | yq -pjson -o=yaml
}

inventory
