# Gateway API Migration with external-dns

This repository has been migrated from Traefik IngressRoute to Kubernetes Gateway API with external-dns for automatic DNS management via Hetzner DNS.

## What Changed

### Before (Traefik IngressRoute)
- **ingress-old.yaml.backup**: Used Traefik-specific `IngressRoute` CRD
- Simple but vendor-locked to Traefik

### After (Gateway API)
- **gateway.yaml**: Defines the Gateway infrastructure
- **httproute.yaml**: Defines application routing (replaces IngressRoute)
- **external-dns.yaml**: Automatically manages DNS records
- Future-proof, vendor-neutral, more powerful

## Architecture Overview

```
Internet
    ↓
[Hetzner DNS] ← managed by external-dns
    ↓
echo.h3rmt.dev → ovh-1.h3rmt.dev (your server IP)
    ↓
[Traefik Gateway] :443 (HTTPS with Let's Encrypt)
    ↓
[HTTPRoute] routes based on hostname
    ↓
[http-echo Service] :8080
    ↓
[http-echo Pods] × 3 replicas
```

## File Breakdown

### k8s/gateway.yaml
Defines the infrastructure layer:

1. **GatewayClass**: Tells Kubernetes to use Traefik as the gateway controller
2. **Gateway**: The actual load balancer with listeners on ports 80/443
3. **ReferenceGrant**: Security policy allowing HTTPRoutes to reference the Gateway

### k8s/httproute.yaml
Defines application routing:

```yaml
annotations:
  external-dns.alpha.kubernetes.io/hostname: echo.h3rmt.dev
  external-dns.alpha.kubernetes.io/target: ovh-1.h3rmt.dev
```

- **hostname**: DNS record to create
- **target**: Where the DNS record should point (your server)
- **parentRefs**: Links to the Gateway
- **hostnames**: Matches incoming requests for `echo.h3rmt.dev`
- **backendRefs**: Routes traffic to the `http-echo` service

### k8s/external-dns.yaml
Automates DNS management:

```yaml
args:
- --source=gateway-httproute  # Watch Gateway API HTTPRoutes
- --provider=hetzner           # Use Hetzner DNS API
- --domain-filter=h3rmt.dev    # Only manage this domain
- --policy=sync                # Keep DNS in sync with k8s
```

**What it does:**
1. Watches HTTPRoute resources with external-dns annotations
2. Creates DNS A record: `echo.h3rmt.dev` → IP of `ovh-1.h3rmt.dev`
3. Creates TXT record: `_external-dns-echo.h3rmt.dev` for ownership tracking
4. Updates/deletes records when HTTPRoutes change

### k8s/traefik.yaml
Updated to enable Gateway API:

```yaml
providers:
  kubernetesGateway:
    enabled: true
```

This tells Traefik to watch for Gateway API resources.

## Deployment Steps

### 1. Get Hetzner DNS API Token
1. Go to Hetzner DNS Console: https://dns.hetzner.com/
2. Navigate to API Tokens
3. Create a new token with DNS write permissions
4. Copy the token

### 2. Update Secret
```bash
# Edit k8s/hetzner-dns-secret.yaml
# Replace YOUR_HETZNER_DNS_API_TOKEN_HERE with your actual token
```

### 3. Install Gateway API CRDs
Gateway API requires CRDs to be installed first:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

### 4. Apply Manifests in Order
```bash
# 1. Update Traefik to enable Gateway API
kubectl apply -f k8s/traefik.yaml

# Wait for Traefik to restart (watch with: kubectl rollout status -n kube-system deployment/traefik)

# 2. Create the Gateway infrastructure
kubectl apply -f k8s/gateway.yaml

# 3. Deploy external-dns
kubectl apply -f k8s/hetzner-dns-secret.yaml
kubectl apply -f k8s/external-dns.yaml

# 4. Deploy the echo app and route
kubectl apply -f k8s/deploy.yaml
kubectl apply -f k8s/httproute.yaml
```

### 5. Verify Everything Works

```bash
# Check if Gateway is ready
kubectl get gateway traefik-gateway

# Check if HTTPRoute is accepted
kubectl get httproute http-echo

# Watch external-dns logs
kubectl logs -n kube-system -l app=external-dns -f

# You should see logs like:
# time="..." level=info msg="Desired change: CREATE echo.h3rmt.dev A [TTL: 300]"
# time="..." level=info msg="Desired change: CREATE _external-dns-echo.h3rmt.dev TXT [TTL: 300]"

# Check DNS propagation (may take 1-2 minutes)
dig echo.h3rmt.dev

# Test the endpoint
curl https://echo.h3rmt.dev
```

## Benefits of Gateway API

### 1. **Role Separation**
- **Infrastructure Team**: Manages `Gateway` (load balancer, TLS, ports)
- **App Teams**: Manage `HTTPRoute` (routing rules per app)

### 2. **More Expressive Routing**
```yaml
# Header-based routing
- matches:
  - headers:
    - name: X-Version
      value: v2

# Query parameter routing
- matches:
  - queryParams:
    - name: env
      value: staging

# Request redirection
- filters:
  - type: RequestRedirect
    requestRedirect:
      scheme: https
```

### 3. **Protocol Support**
- HTTPRoute (HTTP/HTTPS)
- GRPCRoute (gRPC)
- TLSRoute (TLS passthrough)
- TCPRoute (raw TCP)
- UDPRoute (raw UDP)

### 4. **Better Vendor Neutrality**
Works the same across Traefik, Nginx, Istio, Envoy Gateway, etc.

## Adding More Services

To expose another service like `api.h3rmt.dev`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-api
  annotations:
    external-dns.alpha.kubernetes.io/hostname: api.h3rmt.dev
    external-dns.alpha.kubernetes.io/target: ovh-1.h3rmt.dev
spec:
  parentRefs:
  - name: traefik-gateway
  hostnames:
  - api.h3rmt.dev
  rules:
  - backendRefs:
    - name: my-api-service
      port: 8080
```

external-dns will automatically create the DNS record!

## Troubleshooting

### Gateway not ready
```bash
kubectl describe gateway traefik-gateway
# Look for conditions and events
```

### HTTPRoute not working
```bash
kubectl describe httproute http-echo
# Check if it's accepted by the Gateway
```

### DNS not updating
```bash
kubectl logs -n kube-system -l app=external-dns
# Check for Hetzner API errors
```

### Certificate issues
Traefik will automatically request Let's Encrypt certificates for hostnames in HTTPRoutes. Check:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
```

## References

- [Gateway API Docs](https://gateway-api.sigs.k8s.io/)
- [external-dns GitHub](https://github.com/kubernetes-sigs/external-dns)
- [Traefik Gateway API Guide](https://doc.traefik.io/traefik/routing/providers/kubernetes-gateway/)
- [Hetzner DNS API](https://dns.hetzner.com/api-docs)
