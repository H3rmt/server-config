#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dashboard_id=17869
revision=10
output="${script_dir}/victoriametrics-operator-dashboard.json"
tmp="$(mktemp "${script_dir}/.victoriametrics-operator-dashboard.json.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

curl --fail --location --silent --show-error \
  "https://grafana.com/api/dashboards/${dashboard_id}/revisions/${revision}/download" \
  --output "$tmp"

jq --exit-status \
  '.uid == "1H179hunk" and .title == "VictoriaMetrics - operator"' \
  "$tmp" >/dev/null

mv -- "$tmp" "$output"
printf 'Downloaded Grafana dashboard %s revision %s to %s\n' \
  "$dashboard_id" "$revision" "$output"
