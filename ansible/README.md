# Home device monitoring

This directory contains the device-side deployment for the two non-NixOS home
devices. It deliberately does not expose a metrics port on the public
interface and does not require Docker.

## Current cluster limitation

The `next` branch currently deploys only the VictoriaMetrics operator under
`flux/apps/monitoring`; it does not contain a Prometheus, vmagent, Grafana,
Service, PVC, or scrape configuration. Consequently this change does not move
or replace a monitoring data volume. The files below provide the scrape job
and alert rules, but they must be merged into the actual monitoring workload
once that workload is restored or its separate repository is supplied.

Do not apply `prometheus/home-devices.yml` unchanged: replace every
`CHANGE_ME` value with a LAN address or hostname. The metrics endpoints must be
reachable from a pod scheduled on `location=home`, not from the cloud nodes.

The generated scrape job uses ordinary Prometheus `static_configs`, which is
also accepted by VictoriaMetrics' Prometheus-compatible configuration. If the
real deployment uses `VMStaticScrape` or another operator CR instead, translate
the same three targets and labels into that existing mechanism rather than
creating a second Prometheus.

## Deploy the devices

1. Copy `inventory/hosts.example.yml` to `inventory/hosts.yml`.
2. Supply the LAN names/addresses, SSH users and (preferably) an SSH key.
3. Run:

   ```sh
   ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml
   ```

The Pi play installs the distribution `prometheus-node-exporter` package and
binds it to the configured LAN address. The receiver play installs a small
Python standard-library exporter. It does not assume a Python version,
architecture, exporter binary, or init system beyond checking what is
available. For this receiver, which uses classic SysV init and `/etc/rc3.d`,
it installs `/etc/init.d/home-receiver-exporter`, creates the runlevel 3
start link, and starts it through the SysV service interface.

The playbook also installs `metrics-renderer.py` as a temporary SysV service.
For now it only loops and touches
`/var/lib/home-monitoring/renderer-success`; it does not render a dashboard
yet. Its interval is controlled by `receiver_renderer_interval_seconds`.

The receiver playbook supports `opkg` bootstrapping. It disables fact
gathering initially, checks for `/usr/bin/python3` using Ansible's SSH `raw`
transport, installs `receiver_python_package` (default: `python3`) with
`opkg` if needed, and only then starts using normal Ansible modules. The SSH
user therefore needs root access or passwordless sudo, and the configured
opkg feeds must contain the selected Python package.

If Ansible cannot bootstrap because the receiver has no usable Python module,
use the SSH fallback (the receiver still needs `python3`, version 3.6 or
newer):

```sh
ansible/scripts/install-receiver-exporter.sh RECEIVER_LAN SSH_USER RECEIVER_LAN
```

This uses only `ssh`, `scp`, and `sudo`; it does not install a Python package.

The receiver's dashboard renderer must call the supplied success hook after a
successful framebuffer render:

```sh
/opt/home-monitoring/renderer-success
```

The OTBR settings are variables on the `otbr-pi` inventory host. They model
the native `ot-br-posix` installation without assuming the radio or network
interface:

```yaml
otbr_repo_url: https://github.com/openthread/ot-br-posix.git
otbr_repo_dir: /opt/ot-br-posix
otbr_repo_depth: 1
otbr_infra_if_name: wlan0
otbr_thread_if_name: wpan0
otbr_radio_url: spinel+hdlc+uart:///dev/ttyACM0
otbr_agent_service: otbr-agent
otbr_agent_defaults: /etc/default/otbr-agent
```

These values correspond to the upstream native flow:

```sh
apt install git
git clone --recursive --depth=1 "$otbr_repo_url" "$otbr_repo_dir"
cd "$otbr_repo_dir"
./script/bootstrap
INFRA_IF_NAME="$otbr_infra_if_name" ./script/setup
service "$otbr_agent_service" status
```

The radio URL belongs in `OTBR_AGENT_OPTS` in
`$otbr_agent_defaults`. Replace the example `/dev/ttyACM0` with the actual RCP
device. These are configuration variables only; no OTBR deployment is claimed
until a compatible Thread RCP, its firmware, the correct radio path, and the
correct infrastructure interface are supplied.

Set `otbr_enabled: true` on `otbr-pi` to run the native installation tasks.
Those tasks install Git, clone the repository recursively, run
`script/bootstrap`, run `script/setup` with `otbr_infra_if_name`, configure
`OTBR_AGENT_OPTS`, and enable/start `otbr-agent`. The bootstrap and setup steps
use marker files so a later Ansible run does not rebuild them unnecessarily.

The exporter serves system metrics and its own renderer-health metrics on
`receiver_metrics_address:receiver_metrics_port`. A separate renderer
`/metrics` URL can be scraped by setting `renderer_metrics_url`; it is not
assumed to exist.

Disk usage is cached to avoid repeated filesystem queries on the old receiver.
Set `receiver_disk_interval_minutes` in the inventory; it is passed to the
exporter as `--disk-interval-minutes` and defaults to 5. Additional filesystem
paths can be supplied directly with repeated `--disk-path` arguments. The
exporter reads `/etc/os-info` by default and exposes each key/value as
`receiver_os_info{key="...",value="..."} 1`; JSON objects, `KEY=VALUE` files,
and plain text lines are supported. Override the path with `--os-info` if the
receiver stores it elsewhere.

## OTBR prerequisite

The Raspberry Pi still needs a compatible Thread radio (for example, a
supported USB 802.15.4/RCP device), its firmware, and correct permissions.
The Pi 2B alone cannot provide Thread radio functionality. OTBR installation,
radio selection, Thread credentials, and LAN routing remain device-specific
and are intentionally not claimed or automated here. Configure those before
expecting OTBR metrics or Thread operation.

## Connectivity checks

From a temporary pod pinned to the home node, test all configured URLs:

```sh
kubectl run home-metrics-check --rm -it --restart=Never \
  --image=curlimages/curl:8.10.1 \
  --overrides='{"spec":{"nodeSelector":{"location":"home"}}}' -- \
  sh -c 'curl -fsS http://PI_LAN_NAME_OR_IP:9100/metrics >/dev/null && \
         curl -fsS http://RECEIVER_LAN_NAME_OR_IP:9101/metrics >/dev/null'
```

If remote write is used by the real monitoring workload, also test its
cluster-internal Service from this pod (replace the namespace and Service):

```sh
curl -fsS http://PROMETHEUS_SERVICE.PROMETHEUS_NAMESPACE.svc:9090/-/ready
```

Finally query `up{job="home-devices"}` and
`receiver_renderer_success` in the existing Grafana/Prometheus UI. These are
procedures only; no live connectivity is claimed by this repository change.
