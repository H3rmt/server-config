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

## How k3s Helm Integration Works

k3s has a **built-in Helm controller** that watches for special CRDs:

### HelmChart - Install New Charts
```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  repo: https://charts.jetstack.io
  chart: cert-manager
  version: v1.14.0
  targetNamespace: cert-manager
  createNamespace: true
  valuesContent: |-
    installCRDs: true
```

**What happens:**
1. You `kubectl apply -f cert-manager.yaml`
2. k3s Helm controller detects the HelmChart resource
3. It runs: `helm install cert-manager https://charts.jetstack.io/cert-manager`
4. k3s keeps it in sync - update the manifest → automatic `helm upgrade`

### HelmChartConfig - Customize Built-in Charts
```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik  # Must match built-in chart name
  namespace: kube-system
spec:
  valuesContent: |-
    gatewayAPI:
      enabled: true
```

**What happens:**
1. k3s comes with Traefik pre-installed via HelmChart
2. HelmChartConfig lets you override default values
3. k3s merges your values and runs `helm upgrade`

**Check deployed Helm charts:**
```bash
kubectl get helmchart -n kube-system
# NAME           CHART           VERSION
# traefik        traefik         37.1.0+up37.1.0
# cert-manager   cert-manager    v1.14.0
```

## File Structure

### Infrastructure (Helm Charts)
- **cert-manager.yaml** - Installs cert-manager via k3s HelmChart
- **traefik.yaml** - Configures built-in Traefik with Gateway API support

### Gateway API Resources
- **gateway.yaml** - Gateway infrastructure (load balancer + TLS listeners)
- **httproute.yaml** - Application routing rules

### Certificate Management
- **clusterissuer.yaml** - Let's Encrypt issuers (prod + staging)
- **certificate.yaml** - TLS certificate for echo.h3rmt.dev

### DNS Management
- **external-dns.yaml** - Automatic DNS record creation
- **hetzner-dns-secret.yaml** - Hetzner DNS API token (you must fill this in)

### Application
- **deploy.yaml** - Echo server deployment + service

## File Breakdown

### cert-manager.yaml
Installs cert-manager via k3s Helm controller using OCI registry:

```yaml
spec:
  repo: oci://quay.io/jetstack/charts
  chart: cert-manager
  version: v1.20.0
  valuesContent: |-
    crds:
      enabled: true  # Auto-install cert-manager CRDs
```

**What it does:**
- k3s automatically runs `helm install cert-manager` from OCI registry
- Uses official OCI registry at quay.io/jetstack (recommended method)
- Installs cert-manager v1.20.0 with CRDs
- Creates cert-manager namespace and components

### cert-manager-webhook-hetzner.yaml
Installs Hetzner DNS webhook for DNS01 challenges:

```yaml
spec:
  repo: https://vadimkim.github.io/cert-manager-webhook-hetzner
  chart: cert-manager-webhook-hetzner
  version: 1.3.3
```

**What it does:**
- Adds DNS01 challenge support for Hetzner DNS
- Allows cert-manager to create TXT records for ACME validation
- **Enables wildcard certificates** (*.h3rmt.dev)
- Reuses the same Hetzner DNS API secret as external-dns

### cert-manager-rbac.yaml
Grants permissions for cert-manager to use the Hetzner webhook:

```yaml
# ClusterRole for webhook API group
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cert-manager-webhook-hetzner:domain-solver
rules:
- apiGroups: ["acme.hetzner.com"]
  resources: ["*"]
  verbs: ["create"]
```

**What it does:**
- Allows cert-manager service account to create Hetzner webhook resources
- Required for DNS01 challenges to work
- Allows webhook to read secrets in kube-system namespace
- Without this, you get: `"hetzner.acme.hetzner.com is forbidden"` error

### traefik.yaml
Configures built-in Traefik:

```yaml
gatewayAPI:
  enabled: true          # Creates GatewayClass
providers:
  kubernetesGateway:
    enabled: true         # Watch Gateway API resources
```

**What it does:**
- Enables Gateway API support in Traefik
- Creates `GatewayClass` named "traefik" (managed by Helm)
- Makes Traefik watch for Gateway/HTTPRoute resources
- **Removed legacy ACME config** - cert-manager now handles TLS

### clusterissuer.yaml
Defines Let's Encrypt certificate issuers with DNS01 challenge:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: enrico@h3rmt.dev
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - dns01:
        webhook:
          groupName: acme.hetzner.com
          solverName: hetzner
          config:
            secretName: hetzner-dns  # Same secret as external-dns!
            zoneName: h3rmt.dev
```

**What it does:**
- Configures cert-manager to use Let's Encrypt
- **DNS01 challenge** via Hetzner DNS webhook
- Supports **wildcard certificates** (*.h3rmt.dev)
- Works even if port 80 is blocked
- Reuses `hetzner-dns` secret (same as external-dns)
- `letsencrypt-staging` for testing (avoids rate limits)
- `letsencrypt-prod` for production certificates

### certificate.yaml
Requests wildcard TLS certificate:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-h3rmt-dev-tls
spec:
  secretName: wildcard-h3rmt-dev-tls
  issuerRef:
    name: letsencrypt-prod
  dnsNames:
  - "*.h3rmt.dev"  # Covers all subdomains
  - h3rmt.dev      # Apex domain too
```

**What it does:**
1. cert-manager sees this Certificate resource
2. Uses Hetzner DNS webhook to create TXT record: `_acme-challenge.h3rmt.dev`
3. Let's Encrypt validates DNS ownership
4. Stores **wildcard certificate** in Secret `wildcard-h3rmt-dev-tls`
5. All subdomains (echo, api, www, etc.) use this **single certificate**
6. Auto-renews before expiry

**Benefits over HTTP01:**
- One cert for all subdomains
- No need for port 80 access
- Faster (no temporary routes)

### gateway.yaml
Defines Gateway infrastructure:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
spec:
  gatewayClassName: traefik
  listeners:
  - name: websecure
    protocol: HTTPS
    port: 443
    tls:
      certificateRefs:
      - name: wildcard-h3rmt-dev-tls  # Single cert for all subdomains!
```

**What it does:**
- Creates load balancer listeners on ports 80/443
- HTTP listener redirects to HTTPS (configured in Traefik)
- HTTPS listener uses **wildcard certificate** from cert-manager
- All HTTPRoutes automatically get TLS
- GatewayClass links it to Traefik

### httproute.yaml
Defines application routing:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: echo.h3rmt.dev
    external-dns.alpha.kubernetes.io/target: ovh-1.h3rmt.dev
spec:
  parentRefs:
  - name: traefik-gateway
  hostnames:
  - echo.h3rmt.dev
  rules:
  - backendRefs:
    - name: http-echo
      port: 8080
```

**What it does:**
- Links to Gateway via `parentRefs`
- Routes `echo.h3rmt.dev` → `http-echo` service
- external-dns creates DNS record automatically
- Inherits TLS from Gateway

### external-dns.yaml
Automates DNS management:

```yaml
args:
- --source=gateway-httproute  # Watch HTTPRoute resources
- --provider=hetzner           # Use Hetzner DNS API
- --domain-filter=h3rmt.dev    # Only manage this domain
- --policy=sync                # Keep DNS in sync
```

**What it does:**
1. Watches HTTPRoute with `external-dns.alpha.kubernetes.io/hostname` annotation
2. Calls Hetzner DNS API to create:
   - A record: `echo.h3rmt.dev` → IP of `ovh-1.h3rmt.dev`
   - TXT record: `_external-dns-echo.h3rmt.dev` (ownership)
3. Auto-updates/deletes when HTTPRoute changes

## Deployment Steps

### 1. Get Hetzner DNS API Token
1. Go to https://dns.hetzner.com/
2. Navigate to "API Tokens"
3. Create token with DNS write permissions
4. Copy the token

### 2. Update Secrets
```bash
# Edit k8s/hetzner-dns-secret.yaml
# Replace YOUR_HETZNER_DNS_API_TOKEN_HERE with your actual token
```

### 3. Install Gateway API CRDs
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

### 4. Deploy Infrastructure (Helm)
```bash
# Install cert-manager via k3s HelmChart
kubectl apply -f k8s/cert-manager.yaml

# Wait for cert-manager to be ready (~30 seconds)
kubectl wait --for=condition=available --timeout=300s -n cert-manager deployment/cert-manager

# Install Hetzner webhook CRD first
kubectl apply -f k8s/cert-manager-webhook-hetzner-crd.yaml

# Verify CRD is created
kubectl get crd hetzners.acme.hetzner.com
# Should show: hetzners.acme.hetzner.com

# Install Hetzner DNS webhook
kubectl apply -f k8s/cert-manager-webhook-hetzner.yaml

# Wait for webhook to be ready (~20 seconds)
kubectl wait --for=condition=available --timeout=300s -n cert-manager deployment/cert-manager-webhook-hetzner

# IMPORTANT: Apply RBAC for webhook
kubectl apply -f k8s/cert-manager-rbac.yaml

# Verify webhook is working
kubectl get apiservice v1alpha1.acme.hetzner.com
# Should show: Available

# Update Traefik configuration
kubectl apply -f k8s/traefik.yaml

# Wait for Traefik to restart
kubectl rollout status -n kube-system deployment/traefik

# Verify GatewayClass was created by Traefik
kubectl get gatewayclass traefik
```

### 5. Deploy Gateway API Resources
```bash
# Create Let's Encrypt issuers (with DNS01 challenge)
kubectl apply -f k8s/clusterissuer.yaml

# Create Gateway
kubectl apply -f k8s/gateway.yaml

# Create wildcard certificate
kubectl apply -f k8s/certificate.yaml

# Wait for certificate to be ready (DNS01 validation takes ~1-2 minutes)
kubectl wait --for=condition=ready --timeout=300s certificate/wildcard-h3rmt-dev-tls

# Check certificate was issued
kubectl get certificate
# Should show: wildcard-h3rmt-dev-tls   True
```

### 6. Deploy external-dns
```bash
kubectl apply -f k8s/hetzner-dns-secret.yaml
kubectl apply -f k8s/external-dns.yaml
```

### 7. Deploy Application
```bash
kubectl apply -f k8s/deploy.yaml
kubectl apply -f k8s/httproute.yaml
```

## Verification

### Check Gateway Status
```bash
kubectl get gateway traefik-gateway
# NAME               CLASS      ADDRESS         PROGRAMMED   AGE
# traefik-gateway    traefik    10.43.xxx.xxx   True         1m
```

### Check Certificate
```bash
kubectl get certificate
# NAME                      READY   SECRET                    AGE
# wildcard-h3rmt-dev-tls    True    wildcard-h3rmt-dev-tls    2m

kubectl describe certificate wildcard-h3rmt-dev-tls
# Should show: Certificate is up to date and has not expired

# View certificate details
kubectl get secret wildcard-h3rmt-dev-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep -A2 "Subject Alternative Name"
# Should show: DNS:*.h3rmt.dev, DNS:h3rmt.dev
```

### Check HTTPRoute
```bash
kubectl get httproute http-echo
# NAME        HOSTNAMES             AGE
# http-echo   ["echo.h3rmt.dev"]    1m

kubectl describe httproute http-echo
# Should show: Accepted: True
```

### Check external-dns
```bash
kubectl logs -n kube-system -l app=external-dns -f
# Should show:
# level=info msg="Desired change: CREATE echo.h3rmt.dev A"
# level=info msg="Desired change: CREATE _external-dns-echo.h3rmt.dev TXT"
```

### Check DNS
```bash
dig echo.h3rmt.dev
# Should return your server IP

dig TXT _external-dns-echo.h3rmt.dev
# Should return: "heritage=external-dns,external-dns/owner=k3s-cluster"
```

### Test the Endpoint
```bash
curl https://echo.h3rmt.dev
# Should return echo response with request details

# Verify certificate
curl -vI https://echo.h3rmt.dev 2>&1 | grep -i "SSL certificate verify"
# Should show: SSL certificate verify ok
```

## Adding More Services

To expose another service like `api.h3rmt.dev`:

### Just Create HTTPRoute - That's It!
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

**That's it!** 
- **No certificate needed** - wildcard cert already covers *.h3rmt.dev
- **external-dns automatically creates DNS record**
- **TLS automatically works**
- No Gateway changes needed

**For non-wildcard domains** (like example.com), create a Certificate:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-tls
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
```

## Benefits Over Legacy Setup

### Gateway API vs IngressRoute
| Feature | Old (IngressRoute) | New (Gateway API) |
|---------|-------------------|-------------------|
| Standard | Traefik-specific | Kubernetes standard |
| Portability | Vendor lock-in | Works with any controller |
| Role separation | Mixed concerns | Infra vs app teams |
| Protocol support | HTTP only | HTTP, gRPC, TCP, UDP |
| Future support | Maintenance mode | Active development |

### cert-manager vs Traefik ACME
| Feature | Old (Traefik ACME) | New (cert-manager + DNS01) |
|---------|-------------------|------------------------------|
| Certificate storage | Traefik volume | Kubernetes Secrets |
| Challenge type | HTTP01 | **DNS01 via Hetzner** |
| Wildcard certs | Not possible | **Yes! *.h3rmt.dev** |
| Port 80 requirement | Required | **Not needed** |
| Issuer flexibility | Let's Encrypt only | Any CA/issuer |
| Integration | Traefik-specific | Works with any ingress |
| Certificate reuse | Difficult | Easy (shared Secrets) |
| Multiple services | 1 cert per service | **1 wildcard for all** |

### external-dns
- **Automatic**: DNS updates when HTTPRoutes change
- **GitOps friendly**: DNS is declared in manifests
- **Multi-provider**: Works with Hetzner, Cloudflare, AWS, etc.
- **Ownership tracking**: TXT records prevent conflicts

## Troubleshooting

### CRD Error: "could not find the requested resource (post hetzner.acme.hetzner.com)"
```bash
# Error message:
# "the server could not find the requested resource (post hetzner.acme.hetzner.com)"

# Solution: Install the webhook CRD
kubectl apply -f k8s/cert-manager-webhook-hetzner-crd.yaml

# Verify CRD is installed
kubectl get crd hetzners.acme.hetzner.com

# Check if webhook registered its API
kubectl get apiservice v1alpha1.acme.hetzner.com
# Should show: Available

# If still not working, check webhook logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager-webhook-hetzner
```

### RBAC Error: "hetzner.acme.hetzner.com is forbidden"
```bash
# Error message:
# "User \"system:serviceaccount:cert-manager:cert-manager\" cannot create resource \"hetzner\""

# Solution: Apply RBAC configuration
kubectl apply -f k8s/cert-manager-rbac.yaml

# Verify permissions
kubectl auth can-i create hetzner.acme.hetzner.com --as=system:serviceaccount:cert-manager:cert-manager
# Should output: yes
```

### Gateway not ready
```bash
kubectl describe gateway traefik-gateway
# Check conditions and events
```

### Certificate not ready
```bash
kubectl describe certificate wildcard-h3rmt-dev-tls
# Check for DNS01 challenge issues

kubectl get challenges
# See active ACME challenges (DNS01)

kubectl describe challenge <challenge-name>
# Detailed challenge status

# Check if TXT record was created in Hetzner DNS
dig TXT _acme-challenge.h3rmt.dev
# Should show the ACME challenge token

# Check cert-manager webhook logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager-webhook-hetzner
```

### HTTPRoute not accepted
```bash
kubectl describe httproute http-echo
# Check for validation errors
```

### DNS not updating
```bash
kubectl logs -n kube-system -l app=external-dns
# Check for Hetzner API errors
```

### TLS certificate errors
```bash
# Check if wildcard certificate Secret exists
kubectl get secret wildcard-h3rmt-dev-tls

# View certificate details
kubectl get secret wildcard-h3rmt-dev-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Verify it covers your domain
kubectl get secret wildcard-h3rmt-dev-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep "DNS:"
# Should show: DNS:*.h3rmt.dev, DNS:h3rmt.dev
```

## Useful Commands

```bash
# Watch all Gateway API resources
kubectl get gateway,httproute,grpcroute -A

# Watch certificates
kubectl get certificate,certificaterequest,order,challenge -A

# Watch Helm charts
kubectl get helmchart -n kube-system

# Check Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Check external-dns logs
kubectl logs -n kube-system -l app=external-dns -f
```

## References

- [Gateway API Docs](https://gateway-api.sigs.k8s.io/)
- [cert-manager Docs](https://cert-manager.io/docs/)
- [external-dns GitHub](https://github.com/kubernetes-sigs/external-dns)
- [Traefik Gateway API Guide](https://doc.traefik.io/traefik/routing/providers/kubernetes-gateway/)
- [k3s Helm Controller](https://docs.k3s.io/helm)
- [Hetzner DNS API](https://dns.hetzner.com/api-docs)
