# Flux on k3s

## Setup

```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```

## Install Gateway CRDS

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
```

## Remove namespace

```bash
kubectl delete all --all -n <namespace>
# only delete if empty
kubectl delete namespace <namespace>
```

```bash
# run for all that hang
kubectl patch <ocirepository.source.toolkit.fluxcd.io> <traefik> -n flux-system --type=merge -p '{"metadata":{"finalizers":[]}}'
```

## Reset k3s

https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/CLUSTER_UPKEEP.md#cluster-reset
```bash
KUBELET_PATH=$(mount | grep kubelet | cut -d' ' -f3);
${KUBELET_PATH:+umount $KUBELET_PATH}

rm -rf /etc/rancher/{k3s,node};
rm -rf /var/lib/{rancher/k3s,kubelet,longhorn,etcd,cni}
```

## Create and apply initial sops secret

```bash
cat age.key | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin
```

## Encryp secret file using sops

```bash
sops --encrypt --in-place <file>.enc.yaml
```

## Github webhook receiver

```bash
TOKEN=$(head -c 12 /dev/urandom | shasum | cut -d ' ' -f1)
echo $TOKEN

kubectl -n flux-system create secret generic webhook-token --from-literal=token=$TOKEN
```

## Annotate node

```bash
kubectl annotate nodes ovh-1.h3rmt.dev external-dns.alpha.kubernetes.io/ttl=1200
```