#!/usr/bin/env bash
set -euo pipefail

echo "=== Deleting all Gateway API routes in all namespaces ==="
for kind in HTTPRoute TCPRoute TLSRoute UDPRoute; do
  echo "  Deleting ${kind}s..."
  kubectl delete "${kind}" --all -A --ignore-not-found=true
done

echo ""
echo "=== Deleting stale Gateway and GatewayClass ==="
kubectl delete gateway --all -A --ignore-not-found=true
kubectl delete gatewayclass --all -A --ignore-not-found=true

echo ""
echo "=== Force reconciling Traefik HelmRelease (recreates Gateway + GatewayClass) ==="
flux reconcile helmrelease traefik -n kube-system --force

echo ""
echo "=== Waiting for Gateway to get an address ==="
kubectl wait --for=condition=Programmed gateway/traefik -n kube-system --timeout=120s

echo ""
echo "=== Reconciling Flux kustomizations (recreates routes) ==="
flux reconcile kustomization apps -n flux-system
flux reconcile kustomization infrastructure-config -n flux-system

echo ""
echo "=== Waiting for routes to be ready ==="
sleep 5
kubectl get httproute,tcproute,tlsroute,udproute -A

echo ""
echo "Done."