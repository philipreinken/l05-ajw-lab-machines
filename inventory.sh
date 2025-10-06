#!/usr/bin/env bash
set -euo pipefail

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

MAC_LIST_FILE="inventory-macs.txt"

if [ ! -f "$MAC_LIST_FILE" ]; then
  printf "Error: MAC address list file '%s' not found.\n" "$MAC_LIST_FILE" >&2
  exit 1
fi

function arp_scan() {
  local arp_scan_cmd;

  if [ "$(id -u)" -ne 0 ]; then
    arp_scan_cmd="sudo arp-scan"
  else
    arp_scan_cmd="arp-scan"
  fi

  if [ ! -f ".arp-cache" ]; then
    # --retry is used to improve reliability; higher values increase scan time
    ${arp_scan_cmd} --localnet --retry=4 | awk '/^[0-9]/ {print $1, $2}' | uniq | sort -u | tee .arp-cache
  fi

  cat .arp-cache
}

function ip_for_mac() {
  local mac="$1"
  local ip

  if [[ -z "$mac" ]]; then
    # MAC address is required
    return 1
  fi

  ip=$(arp_scan | grep "$mac" | awk '{print $1}')

  if [[ -z "$ip" ]]; then
    # No IP found for MAC address $mac
    return
  fi

  echo "$ip"
}

function full_info() {
  while read -r -a line; do
    # echo "Processing MAC: ${line[0]}, Hostname: ${line[1]}" >&2

    local host_ip; host_ip=$(ip_for_mac "${line[0]}")

    if [ -z "$host_ip" ]; then
      # echo "Skipping ${line[1]} due to missing IP for MAC ${line[0]}" >&2
      continue
    fi

    jq -n \
      --arg mac "${line[0]}" \
      --arg hostname "${line[1]}" \
      --arg ip "${host_ip}" \
      '{ inventory_hostname: $hostname, ansible_user: "schule", ansible_host: $ip, security_ssh_allowed_users: [ "schule", "L05" ] }'
  done <${MAC_LIST_FILE} | jq -s
}

function inventory() {
  full_info | jq -s '{ _meta: { hostvars: .[] | map( { (.inventory_hostname | tostring): . } ) | add }, all: { children: [ "classroom" ] }, classroom: { hosts: .[] | map( .inventory_hostname ) } }'
}

#function override() {
#  jq '._meta.hostvars["l05_000"].ansible_user = "preinstalled"'
#}

function main() {
  inventory # | override
}

main "${@}"
