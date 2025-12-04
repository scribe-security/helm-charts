# Attestation Store Helm Chart

This Helm chart deploys the Attestation Store, a secure storage and verification system for software attestations and evidence, on Kubernetes.

## Overview

The Attestation Store provides a centralized repository for storing, managing, and verifying software supply chain attestations including SBOMs, vulnerability scans, and policy compliance results.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistent storage)
- (Optional) Ingress controller (nginx-ingress, AWS ALB, etc.)
- (Optional) cert-manager for TLS certificates

## Deployment Modes

This chart supports three deployment modes to fit different use cases:

### 1. Proof-of-Concept (PoC) Mode - **Default**

Minimal setup for testing, development, and demos.

**Features:**
- 1 replica
- SQLite database (no external database required)
- Local file storage (PersistentVolume)
- No MinIO or PostgreSQL
- Optional Ingress

**Use Cases:** Quick testing, development, demos, learning

**Installation:**
```bash
helm install attstore ./attstore
```

### 2. Production Mode (Stand-Alone Full System)

Complete self-contained deployment suitable for production on-premises environments.

**Features:**
- 2 replicas (configurable)
- PostgreSQL database (StatefulSet)
- MinIO object storage (Deployment)
- Optional PgBouncer connection pooler
- Ingress enabled with TLS
- Pod disruption budget

**Use Cases:** Production on-premises, air-gapped environments, private clouds

**Installation:**
```bash
# First, fetch the chart to get values files
helm pull scribe/attstore --untar

# Install with production values
helm install attstore scribe/attstore \
  -f attstore/values-production.yaml \
  --set database.postgresql.password="change-me-db-password" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123"

# Or from local directory (development)
helm install attstore ./attstore -f values-production.yaml \
  --set database.postgresql.password="change-me-db-password" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123"
```

### 3. AWS Deployment Mode

Cloud-native deployment using AWS managed services.

**Features:**
- 2+ replicas with autoscaling
- AWS RDS PostgreSQL (external)
- AWS S3 for object storage
- IRSA (IAM Roles for Service Accounts) for AWS access
- ALB Ingress Controller
- Anti-affinity for multi-AZ deployment

**Use Cases:** Production AWS/EKS deployments

**Installation:**
```bash
# Prerequisites: Create RDS instance, S3 bucket, and IAM role for IRSA

# First, fetch the chart to get values files
helm pull scribe/attstore --untar

# Install with AWS values
helm install attstore scribe/attstore \
  -f attstore/values-aws.yaml \
  --set serviceAccount.annotations."eks\.amazonaws\.io/role-arn"="arn:aws:iam::ACCOUNT_ID:role/attstore-s3-access" \
  --set storage.cloudStorage.aws.bucket="my-attstore-bucket" \
  --set storage.cloudStorage.aws.region="us-east-1" \
  --set database.externalDatabase.host="mydb.xxxx.us-east-1.rds.amazonaws.com" \
  --set database.externalDatabase.password="RDSPassword" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123"

# Or from local directory (development)
helm install attstore ./attstore -f values-aws.yaml \
  --set serviceAccount.annotations."eks\.amazonaws\.io/role-arn"="arn:aws:iam::ACCOUNT_ID:role/attstore-s3-access" \
  --set storage.cloudStorage.aws.bucket="my-attstore-bucket" \
  --set storage.cloudStorage.aws.region="us-east-1" \
  --set database.externalDatabase.host="mydb.xxxx.us-east-1.rds.amazonaws.com" \
  --set database.externalDatabase.password="RDSPassword" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123"
```

## Installation

### Add Helm Repository

```bash
# Add the Scribe Helm repository
helm repo add scribe https://scribe-security.github.io/helm-charts
helm repo update
```

### Quick Start (PoC Mode)

```bash
# Install from Scribe repository
helm install attstore scribe/attstore

# Or install from local directory (for development)
helm install attstore ./attstore

# With custom release name and namespace
helm install my-attstore scribe/attstore --namespace attstore --create-namespace
```

### Configuration

All configuration is done via the `values.yaml` file or `--set` flags. See [Configuration](#configuration-reference) section for details.

#### Essential Configuration (Production)

**⚠️ CRITICAL:** Always set these values for production deployments:

```bash
--set database.postgresql.password="change-me-db-password"
--set config.sessionSecret="your-session-secret-change-me"
--set config.jwtSecretKey="your-jwt-secret-change-me"
--set config.admin.password="YourSecurePassword123"
```

**Note:** Replace these example values with your own secure secrets in production.

## Configuration Reference

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `ghcr.io/scribe-security/attstore` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full name | `""` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `5003` |
| `service.nodePort` | NodePort (if type=NodePort) | `nil` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable Ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | TLS configuration | `[]` |

### Application Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.port` | Application port | `5003` |
| `config.sessionSecret` | Flask session secret | Auto-generated |
| `config.jwtSecretKey` | JWT signing key | Auto-generated |
| `config.admin.username` | Admin username | `admin` |
| `config.admin.password` | Admin password | `admin#admin` ⚠️ |
| `config.admin.email` | Admin email | `admin@example.com` |
| `config.presignedUrlExpiration` | Presigned URL expiration (seconds) | `3600` |

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storage.type` | Storage type: `FILE_MOUNT` or `CLOUD_STORAGE` | `FILE_MOUNT` |
| `storage.fileMount.path` | Path for file storage | `/app/storage` |
| `storage.persistence.enabled` | Enable persistent storage | `true` |
| `storage.persistence.size` | PVC size | `10Gi` |
| `storage.persistence.storageClass` | Storage class | `""` (default) |
| `storage.cloudStorage.provider` | Cloud provider: `AWS` or `MINIO` | `AWS` |
| `storage.cloudStorage.aws.bucket` | S3 bucket name | `""` |
| `storage.cloudStorage.aws.region` | AWS region | `us-east-1` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.type` | Database type: `sqlite` or `postgresql` | `sqlite` |
| `database.postgresql.enabled` | Enable bundled PostgreSQL | `false` |
| `database.postgresql.host` | PostgreSQL host | Auto-generated |
| `database.postgresql.port` | PostgreSQL port | `5432` |
| `database.postgresql.database` | Database name | `attstoredb` |
| `database.postgresql.username` | Database username | `attstoreuser` |
| `database.postgresql.password` | Database password | Auto-generated |
| `database.postgresql.persistence.enabled` | Enable PostgreSQL persistence | `true` |
| `database.postgresql.persistence.size` | PVC size | `20Gi` |
| `database.externalDatabase.enabled` | Use external database | `false` |
| `database.externalDatabase.host` | External DB host | `""` |
| `database.externalDatabase.password` | External DB password | `""` |

### MinIO Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.enabled` | Enable MinIO deployment | `false` |
| `minio.rootUser` | MinIO root user | `minioadmin` |
| `minio.rootPassword` | MinIO root password | Auto-generated |
| `minio.bucket` | Bucket name | `attstorebucket` |
| `minio.persistence.enabled` | Enable MinIO persistence | `true` |
| `minio.persistence.size` | PVC size | `50Gi` |

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `70` |

## Examples

### Example 1: PoC with NodePort Access

```bash
helm install attstore scribe/attstore \
  --set service.type=NodePort \
  --set service.nodePort=30503
```

### Example 2: Production with Custom Storage Class

```bash
# Fetch the chart first
helm pull scribe/attstore --untar

# Install with custom storage classes
helm install attstore scribe/attstore \
  --version 1.0.0 \
  -f attstore/values-production.yaml \
  --set database.postgresql.password="change-me-db-password" \
  --set database.postgresql.persistence.storageClass="fast-ssd" \
  --set minio.persistence.storageClass="standard" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123"
```

### Example 3: AWS with S3 and RDS

```bash
# Fetch the chart first
helm pull scribe/attstore --untar

# Install with AWS values
helm install attstore scribe/attstore \
  -f attstore/values-aws.yaml \
  --set database.externalDatabase.host="mydb.xyz.us-east-1.rds.amazonaws.com" \
  --set database.externalDatabase.password="RDSPassword" \
  --set storage.cloudStorage.aws.bucket="my-bucket" \
  --set storage.cloudStorage.aws.region="us-east-1" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123"
```

## Advanced Configuration

### Ingress Setup

Ingress configuration is the responsibility of your organization and depends on your existing ingress controller (nginx, Traefik, AWS ALB, etc.).

**Example with nginx-ingress:**

```bash
# Fetch the chart first
helm pull scribe/attstore --untar

# Install with ingress enabled
helm install attstore scribe/attstore \
  -f attstore/values-production.yaml \
  --set database.postgresql.password="change-me-db-password" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123" \
  --set ingress.enabled=true \
  --set ingress.className="nginx" \
  --set 'ingress.hosts[0].host=attstore.yourdomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix'
```

**Example with TLS/HTTPS:**

```bash
helm install attstore scribe/attstore \
  -f attstore/values-production.yaml \
  --set database.postgresql.password="change-me-db-password" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123" \
  --set ingress.enabled=true \
  --set ingress.className="nginx" \
  --set 'ingress.hosts[0].host=attstore.yourdomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
  --set 'ingress.tls[0].secretName=attstore-tls' \
  --set 'ingress.tls[0].hosts[0]=attstore.yourdomain.com'
```

**Note:** Ensure your TLS certificate exists as a Kubernetes secret or use cert-manager to automatically provision certificates.

### File Storage Configuration (FILE_MOUNT Mode)

When using `FILE_MOUNT` storage type (default in PoC mode), the application stores attestation files on a local persistent volume and generates upload/download URLs for clients. 

**⚠️ CRITICAL:** The `storage.fileMount.baseUrl` setting determines what URL clients receive for uploading/downloading files. If not configured correctly, clients outside the cluster will receive internal cluster URLs that they cannot access.

#### Configuration Options:

**Option 1: Enable Ingress (Recommended)**

When ingress is enabled, the chart automatically uses the ingress host as the base URL:

```bash
helm install attstore scribe/attstore \
  --set ingress.enabled=true \
  --set ingress.className="nginx" \
  --set 'ingress.hosts[0].host=attstore.yourdomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix'

# Files will be accessible at: https://attstore.yourdomain.com/evidence/download/...
```

**Option 2: Set Base URL Explicitly**

For LoadBalancer or NodePort services, or when using port-forwarding:

```bash
# For LoadBalancer
helm install attstore scribe/attstore \
  --set service.type=LoadBalancer \
  --set storage.fileMount.baseUrl="http://your-loadbalancer-ip:5003"

# For NodePort
helm install attstore scribe/attstore \
  --set service.type=NodePort \
  --set service.nodePort=30503 \
  --set storage.fileMount.baseUrl="http://your-node-ip:30503"

# For port-forwarding (development)
helm install attstore scribe/attstore \
  --set storage.fileMount.baseUrl="http://localhost:5003"
# Then: kubectl port-forward svc/attstore 5003:5003
```

**Option 3: Default (Not Recommended for External Clients)**

If neither ingress is enabled nor `baseUrl` is set, the chart defaults to the internal Kubernetes service URL (e.g., `http://attstore:5003`). This **will NOT work** for clients outside the cluster!

#### Troubleshooting

If clients are receiving URLs like `http://attstore:5003` or internal cluster names:

1. Check if ingress is enabled and properly configured
2. Set `storage.fileMount.baseUrl` explicitly to an externally accessible URL
3. Verify the URL is reachable from where your clients are running

```bash
# Check current configuration
helm get values attstore

# Update the baseUrl
helm upgrade attstore scribe/attstore \
  --set storage.fileMount.baseUrl="https://your-external-url.com" \
  --reuse-values
```

### PgBouncer Connection Pooling

PgBouncer is optional and only needed for high-scale deployments (10+ replicas or 100+ concurrent connections). 
**Not needed for AWS RDS** (use RDS Proxy instead if needed).

```bash
# Fetch the chart first
helm pull scribe/attstore --untar

# Enable PgBouncer in production mode
helm install attstore scribe/attstore \
  -f attstore/values-production.yaml \
  --set pgbouncer.enabled=true \
  --set database.postgresql.password="change-me-db-password" \
  --set config.sessionSecret="my-session-secret-change-in-production" \
  --set config.jwtSecretKey="my-jwt-secret-change-in-production" \
  --set config.admin.password="SecurePassword123"

# The app will automatically connect through PgBouncer instead of directly to PostgreSQL
```

When enabled, PgBouncer sits between your app pods and PostgreSQL, pooling connections:
- Default pool size: 20 connections to PostgreSQL
- Max client connections: 600
- Pool mode: transaction (best for most web apps)

## Upgrading

```bash
# Update repository
helm repo update

# Upgrade to latest version
helm upgrade attstore scribe/attstore

# Upgrade with specific version
helm upgrade attstore scribe/attstore --version 1.2.3

# Upgrade with custom values (fetch chart first for values files)
helm pull scribe/attstore --untar
helm upgrade attstore scribe/attstore \
  -f attstore/values-production.yaml

# Upgrade with specific changes
helm upgrade attstore scribe/attstore \
  --set image.tag="v1.2.3" \
  --set replicaCount=3
```

## Uninstallation

```bash
helm uninstall attstore --namespace attstore

# Note: PVCs are not deleted automatically
kubectl delete pvc -l app.kubernetes.io/instance=attstore -n attstore
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=attstore
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check Database Connection

```bash
kubectl exec -it deployment/attstore -- python -c "
from app import app, db
with app.app_context():
    from sqlalchemy import text
    with db.engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('Database connection OK')
"
```

### Access Application Logs

```bash
kubectl logs -f deployment/attstore
```

### Common Issues

1. **Pods stuck in Pending:** Check PVC provisioning and storage class availability
2. **Database connection errors:** Verify PostgreSQL pod is running and credentials are correct
3. **S3 access denied:** Check IRSA configuration and IAM policy permissions
4. **Ingress not working:** Verify ingress controller is installed and configured

## Security Best Practices

1. **Always change default credentials** in production
2. **Use strong randomly generated secrets** for session and JWT keys
3. **Enable TLS/HTTPS** via Ingress with valid certificates
4. **Use IRSA** for AWS deployments instead of static credentials
5. **Restrict network access** using NetworkPolicies
6. **Use external secret management** (AWS Secrets Manager, HashiCorp Vault, etc.)
7. **Enable PodSecurityPolicies** or PodSecurity admission controller
8. **Regularly update** the image to latest security patches

## Development

### Testing the Chart

```bash
# Search for available versions
helm search repo scribe/attstore --versions

# Fetch the chart locally for inspection
helm pull scribe/attstore --untar

# Lint the chart
helm lint ./attstore

# Dry run installation
helm install attstore scribe/attstore --dry-run --debug

# Template rendering with production values
helm template attstore scribe/attstore \
  -f attstore/values-production.yaml > output.yaml
```

### Packaging

```bash
helm package ./attstore
```

## Support

- **Issues:** https://github.com/scribe-security/attstore/issues
- **Documentation:** https://github.com/scribe-security/attstore
- **Email:** support@scribesecurity.com

## License

See the main repository for license information.
