# Gateway API with cert-manager and external-dns

This k3s cluster uses modern Kubernetes Gateway API for routing, cert-manager for TLS certificates, and external-dns for automatic DNS management via Hetzner DNS.

## Architecture Overview

```
Internet
    ↓
[Hetzner DNS] ← managed by external-dns
    ↓
echo.h3rmt.dev → ovh-1.h3rmt.dev (your server IP)
    ↓
[Traefik Gateway] :443 (HTTPS)
    ↓ [cert-manager provides TLS certificates]
[HTTPRoute] routes based on hostname
    ↓
[http-echo Service] :8080
    ↓
[http-echo Pods] × 3 replicas
```

## File Structure

### `cert-manager/`
- **infrastructure.yaml** - Installs cert-manager and Hetzner DNS webhook via k3s HelmCharts.
- **issuers.yaml** - Let's Encrypt ClusterIssuers (prod + staging).
- **hetzner-dns-secret.yaml** - Hetzner DNS API token for cert-manager.

### `external-dns/`
- **all.yaml** - Namespace, RBAC, and Deployment for external-dns.
- **hetzner-dns-secret-ext-dns.yaml** - Hetzner DNS API token for external-dns.

### `traefik/`
- **traefik.yaml** - Configures built-in Traefik with Gateway API support.
- **gateway.yaml** - Gateway infrastructure (load balancer + TLS listeners).
- **certificate.yaml** - Wildcard TLS certificate for h3rmt.dev.

### `app/`
- **echo-app.yaml** - Echo server deployment + service.
- **echo-route.yaml** - HTTPRoute rules for the echo server.

## Deployment Steps

### 1. Get Hetzner DNS API Token
1. Go to https://dns.hetzner.com/
2. Navigate to "API Tokens"
3. Create token with DNS write permissions
4. Copy the token

### 2. Update Secrets
```bash
# Edit k8s/cert-manager/hetzner-dns-secret.yaml
# Edit k8s/external-dns/hetzner-dns-secret-ext-dns.yaml
# Replace YOUR_HETZNER_DNS_API_TOKEN_HERE with your actual token
```

### 3. Install Gateway API CRDs
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
# Install Traefik RBACs.
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml
```

### 4. Deploy Infrastructure
```bash
# Install cert-manager and webhook
kubectl apply -f k8s/cert-manager/infrastructure.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=available --timeout=300s -n cert-manager deployment/cert-manager

# Install Hetzner DNS API Secret in cert-manager namespace
kubectl apply -f k8s/cert-manager/hetzner-dns-secret.yaml

# Create Let's Encrypt issuers
kubectl apply -f k8s/cert-manager/issuers.yaml

# Update Traefik configuration
kubectl apply -f k8s/traefik/traefik.yaml

# Create Gateway and Wildcard Certificate
kubectl apply -f k8s/traefik/certificate.yaml
kubectl apply -f k8s/traefik/gateway.yaml
```

### 5. Deploy external-dns
```bash
kubectl apply -f k8s/external-dns/hetzner-dns-secret-ext-dns.yaml
kubectl apply -f k8s/external-dns/all.yaml
```

### 6. Deploy Application
```bash
kubectl apply -f k8s/app/echo-app.yaml
kubectl apply -f k8s/app/echo-route.yaml
```

## Troubleshooting & Verification

### Check Gateway Status
```bash
kubectl get gateway traefik-gateway
kubectl describe gateway traefik-gateway
```

### Check Certificate
```bash
kubectl get certificate
kubectl describe certificate wildcard-h3rmt-dev-tls
```

### Useful Commands
```bash
# Watch all Gateway API resources
kubectl get gateway,httproute,grpcroute -A

# Watch certificates
kubectl get certificate,certificaterequest,order,challenge -A

# Check logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f
kubectl logs -n cert-manager -l app=cert-manager -f
kubectl logs -n external-dns -l app=external-dns -f
```
