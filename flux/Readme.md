# Flux on k3s

## Setup (on the initial k3s server with clusterInit = true)

### Flux controller

```bash
nix-shell -p kubernetes-helm

helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
--namespace flux-system \
--kubeconfig /etc/rancher/k3s/k3s.yaml \
--create-namespace
```

### Install Gateway CRDS

```bash
# doesnt have tcp route
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml

# has tcproute
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/experimental-install.yaml
```

## Create and apply initial sops secret

```bash
cat age.key | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin
```

## Annotate node (external-dns)

```bash
kubectl annotate nodes ovh-1.h3rmt.dev external-dns.kubernetes.io/ttl=1200
```

## Apply Flux config

```bash
kubectl apply -f ./flux.yaml
```

## Github webhook receiver

```bash
TOKEN=$(head -c 12 /dev/urandom | shasum | cut -d ' ' -f1)
echo $TOKEN

kubectl -n flux-system create secret generic webhook-token --from-literal=token=$TOKEN

kubectl -n flux-system describe receiver github-webhook-receiver
# Enter url on github
```

## Other

## View Flux Operator and Headlamp

```bash
kubectl -n kube-system port-forward service/headlamp 50000:80 &
kubectl -n flux-system port-forward service/flux-operator 50001:9080 &

# Get secret for headlamp login
kubectl create token headlamp-admin -n kube-system
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


## Encryp secret file using sops

```bash
sops --encrypt --in-place <file>.enc.yaml
```

## Reset k3s

https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/CLUSTER_UPKEEP.md#cluster-reset

```bash
KUBELET_PATH=$(mount | grep kubelet | cut -d' ' -f3);
${KUBELET_PATH:+umount $KUBELET_PATH}

rm -rf /etc/rancher/{k3s,node};
rm -rf /var/lib/{rancher/k3s,kubelet,longhorn,etcd,cni}
```
