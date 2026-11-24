#!/usr/bin/env bash
set -euo pipefail

echo 'Downloading Grafana dashboards...'

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp "${script_dir}/.dashboard-XXXXXX.json")"
trap 'rm -f "$tmp" "${tmp}.adapted"' EXIT

IDS=("17869" "17347" "16888" "20417")
REVS=("10" "9" "14" "4")
OUT_NAMES=("victoriametrics-operator-dashboard.json" "traefik-dashboard.json" "longhorn-dashboard.json" "cloudnativepg-dashboard.json")
UIDS=("1H179hunk" "n5bu_kv4k" "ozk-lh-mon" "cloudnative-pg")

for i in "${!IDS[@]}"; do
  printf '\e[34m==> Downloading Grafana dashboard %s revision %s...\e[0m\n' "${IDS[$i]}" "${REVS[$i]}"
  curl --fail --location --show-error "https://grafana.com/api/dashboards/${IDS[$i]}/revisions/${REVS[$i]}/download" --output "$tmp"
  if ! jq --exit-status --arg expected_uid "${UIDS[$i]}" '.uid == $expected_uid' "$tmp" > /dev/null; then
    actual_uid="$(jq -c '.uid' "$tmp" 2>/dev/null)" || actual_uid='<invalid JSON>'
    printf '\e[31m==> Error: dashboard %s revision %s has an unexpected UID (expected %s, got %s)\e[0m\n' "${IDS[$i]}" "${REVS[$i]}" "${UIDS[$i]}" "$actual_uid" >&2
    exit 1
  fi
  if [[ "${IDS[$i]}" == "16888" ]]; then
    jq -f "${script_dir}/longhorn-dashboard.jq" "$tmp" > "${tmp}.adapted"
    mv "${tmp}.adapted" "$tmp"
  elif [[ "${IDS[$i]}" == "20417" ]]; then
    jq -f "${script_dir}/cloudnativepg-dashboard.jq" "$tmp" > "${tmp}.adapted"
    mv "${tmp}.adapted" "$tmp"
  fi
  mv "$tmp" "${script_dir}/${OUT_NAMES[$i]}"
  printf '\e[32m==> Downloaded Grafana dashboard %s revision %s to %s\e[0m\n\n' "${IDS[$i]}" "${REVS[$i]}" "${OUT_NAMES[$i]}"
done
