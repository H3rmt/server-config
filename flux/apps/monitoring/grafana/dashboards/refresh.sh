#!/usr/bin/env bash
set -euo pipefail

echo 'Downloading Grafana dashboards...'

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp "${script_dir}/.dashboard-XXXXXX.json")"
trap 'rm -f "$tmp"' EXIT

IDS=("17869" "17347")
REVS=("10" "9")
OUT_NAMES=("victoriametrics-operator-dashboard.json" "traefik-dashboard.json")
UIDS=("1H179hunk" "an5bu_kv4k")

for i in "${!IDS[@]}"; do
  printf '\e[34m==> Downloading Grafana dashboard %s revision %s...\e[0m\n' "${IDS[$i]}" "${REVS[$i]}"
  curl --fail --location --show-error "https://grafana.com/api/dashboards/${IDS[$i]}/revisions/${REVS[$i]}/download" --output "$tmp"
  if ! jq --exit-status --arg expected_uid "${UIDS[$i]}" '.uid == $expected_uid' "$tmp" > /dev/null; then
    printf '\e[31m==> Error: dashboard %s revision %s has an unexpected UID (expected %s)\e[0m\n' "${IDS[$i]}" "${REVS[$i]}" "${UIDS[$i]}" >&2
    exit 1
  fi
  mv "$tmp" "${script_dir}/${OUT_NAMES[$i]}"
  printf '\e[32m==> Downloaded Grafana dashboard %s revision %s to %s\e[0m\n\n' "${IDS[$i]}" "${REVS[$i]}" "${OUT_NAMES[$i]}"
done


