# Environment Strategy

## Three-Tier Environment Architecture

This project implements a **three-tier environment strategy** following enterprise best practices:

```
Development → Staging → Production
```

## Environment Configurations

### 🔧 Development (`values-dev.yaml`)

**Purpose**: Local development and testing
**Current Status**: ✅ Running (2 nodes)

**Resources**:
- Application services: 30m CPU, 64Mi memory
- Databases: 50m CPU, 128-256Mi memory
- **Total**: ~430m CPU

**Characteristics**:
- Minimal resources for cost efficiency
- Latest image tags for rapid iteration
- Single replica per service
- Fits on 2-node cluster (Standard_DC2s_v3)

**Usage**:
```bash
./deploy-robot-shop.sh dev
```

**Ideal For**:
- Feature development
- Bug fixes
- Initial testing
- Cost-sensitive environments

---

### 🧪 Staging (`values-staging.yaml`)

**Purpose**: Pre-production testing and validation
**Current Status**: ⚪ Not deployed

**Resources**:
- Application services: 40m CPU, 96Mi memory
- Databases: 75m CPU, 192-384Mi memory
- **Total**: ~600m CPU

**Characteristics**:
- Production-like configuration
- Specific version tags (matching prod)
- Integration testing environment
- Requires 3 nodes or autoscaling

**Usage**:
```bash
./deploy-robot-shop.sh staging
```

**Ideal For**:
- Integration testing
- Performance testing
- UAT (User Acceptance Testing)
- Production deployment rehearsal
- Validating infrastructure changes

---

### 🚀 Production (`values-prod.yaml`)

**Purpose**: Live production workloads
**Current Status**: ⚪ Not deployed

**Resources**:
- Application services: 50m CPU, 128Mi memory
- Databases: 100m CPU, 256-512Mi memory
- **Total**: ~750m CPU

**Characteristics**:
- Optimized resources with headroom
- Specific version tags (immutable)
- High availability ready
- Autoscaling enabled (min=2, max=5 nodes)
- Production-grade limits

**Usage**:
```bash
./deploy-robot-shop.sh prod
```

**Ideal For**:
- Live customer traffic
- Production workloads
- High availability requirements
- Performance-critical applications

---

## Resource Comparison

| Environment | App CPU | DB CPU | App Memory | DB Memory | Total CPU | Nodes Needed |
|-------------|---------|--------|------------|-----------|-----------|--------------|
| Dev         | 30m     | 50m    | 64Mi       | 128-256Mi | ~430m     | 2            |
| Staging     | 40m     | 75m    | 96Mi       | 192-384Mi | ~600m     | 3            |
| Prod        | 50m     | 100m   | 128Mi      | 256-512Mi | ~750m     | 3-5          |

*Note: Total CPU includes system pods (~800m)*

---

## Deployment Workflow

### Recommended Promotion Path

```
1. Develop → Deploy to Dev
2. Test → Deploy to Staging
3. Validate → Deploy to Production
```

### Example Workflow

```bash
# 1. Deploy new feature to dev
git checkout feature/new-feature
./deploy-robot-shop.sh dev

# 2. Test and validate
kubectl get pods -n robot-shop
# Run tests...

# 3. Promote to staging
git checkout main
git merge feature/new-feature
./deploy-robot-shop.sh staging

# 4. Integration testing
# Run full test suite...

# 5. Deploy to production
./deploy-robot-shop.sh prod
```

---

## Environment Variables

Each environment can override:

- **Image tags**: `latest` (dev) vs specific versions (staging/prod)
- **Pull policy**: `IfNotPresent` (dev) vs `Always` (prod)
- **Resources**: CPU and memory requests/limits
- **Replicas**: Single (dev) vs multiple (prod)
- **Autoscaling**: Disabled (dev) vs enabled (prod)
- **Storage class**: Same across all (managed-csi)

---

## Current Deployment

**Active Environment**: Development
- **Cluster**: robot-shop-dev-aks
- **Nodes**: 2 × Standard_DC2s_v3
- **Pods**: 12/12 Running
- **CPU Usage**: 6-7%
- **Web URL**: http://57.151.39.73:8080

---

## Infrastructure Mapping

### Terraform Environments

The Terraform configuration supports the same three-tier strategy:

```
terraform/environments/
├── dev/          # Currently deployed
├── staging/      # To be created
└── prod/         # To be created
```

### Recommended Setup

**Development**:
- AKS: 2 nodes, Standard_DC2s_v3
- Autoscaling: min=2, max=3
- Cost: ~$160/month

**Staging**:
- AKS: 2 nodes, Standard_D2s_v3
- Autoscaling: min=2, max=4
- Cost: ~$180/month

**Production**:
- AKS: 3 nodes, Standard_D4s_v3
- Autoscaling: min=3, max=10
- Cost: ~$400/month

---

## Best Practices

### ✅ Do

- Always test in dev first
- Validate in staging before prod
- Use specific image tags in staging/prod
- Monitor resource usage per environment
- Keep staging config close to prod
- Document environment differences

### ❌ Don't

- Deploy directly to prod without staging
- Use `latest` tag in production
- Skip testing in lower environments
- Over-provision dev resources
- Under-provision prod resources

---

## Switching Environments

### Current Deployment (Dev)
```bash
# Check current
helm list -n robot-shop

# Upgrade to staging config
./deploy-robot-shop.sh staging
```

### New Deployment
```bash
# Deploy to specific environment
./deploy-robot-shop.sh [dev|staging|prod]
```

---

## Monitoring Per Environment

```bash
# Check pods
kubectl get pods -n robot-shop

# Check resource usage
kubectl top nodes
kubectl top pods -n robot-shop

# Check services
kubectl get svc -n robot-shop
```

---

## Summary

✅ **Three-tier strategy implemented**
✅ **Clear resource progression** (dev → staging → prod)
✅ **Enterprise best practices**
✅ **Cost-optimized per environment**
✅ **Easy environment switching**
✅ **Production-ready architecture**

This structure demonstrates professional DevOps practices and is ideal for:
- Portfolio projects
- Job interviews
- Production deployments
- Team collaboration
