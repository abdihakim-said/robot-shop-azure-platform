# Helm Template Fixes Applied

## Problem Summary
The Robot Shop Helm chart had hardcoded resource requests/limits in all deployment templates that ignored values from the values file. This caused:
1. All pods requesting 100m CPU regardless of values file settings
2. Total CPU requests (12 services × 100m = 1200m + system pods) exceeded available capacity on 2-node cluster
3. 3 pods stuck in Pending state due to insufficient CPU
4. Redis using AWS storage class (gp2) instead of Azure (managed-csi)

## Root Cause Analysis
- **Templates**: All 11 deployment files + 1 statefulset had hardcoded resources
- **Storage**: Redis statefulset had hardcoded `storageClassName: gp2`
- **Total CPU needed**: ~2000m with system pods
- **Available CPU**: ~1900m on 2× Standard_DC2s_v3 nodes (95-97% utilization)

## Files Fixed

### 1. Deployment Templates (Made resources configurable)
Fixed to use `{{- with .Values.<service>.resources }}` pattern:

- `helm/templates/cart-deployment.yaml`
- `helm/templates/catalogue-deployment.yaml`
- `helm/templates/dispatch-deployment.yaml`
- `helm/templates/mongodb-deployment.yaml` (removed orphaned requests)
- `helm/templates/mysql-deployment.yaml` (removed orphaned requests)
- `helm/templates/payment-deployment.yaml`
- `helm/templates/rabbitmq-deployment.yaml` (removed orphaned requests)
- `helm/templates/ratings-deployment.yaml` (removed orphaned requests)
- `helm/templates/shipping-deployment.yaml` (removed orphaned requests)
- `helm/templates/user-deployment.yaml`
- `helm/templates/web-deployment.yaml`

### 2. StatefulSet Template (Storage + Resources)
- `helm/templates/redis-statefulset.yaml`
  - Changed: `storageClassName: gp2` → `storageClassName: {{ .Values.redis.storageClassName | default "gp2" }}`
  - Made resources configurable with `{{- with .Values.redis.resources }}`

## Changes Made

### Before (Hardcoded):
```yaml
resources:
  limits:
    cpu: 200m
    memory: 100Mi
  requests:
    cpu: 100m
    memory: 50Mi
```

### After (Configurable):
```yaml
{{- with .Values.<service>.resources }}
resources:
  {{- toYaml . | nindent 10 }}
{{- end }}
```

## Values File Created

### `helm/values-final.yaml`
Optimized resource allocation for 2-node cluster:

**Total CPU Requests**: ~430m (vs 1200m before)
- Application services: 30m each (9 services = 270m)
- Databases: 50m each (3 services = 150m)
- System pods: ~800m
- **Total**: ~1230m (fits within 1900m available)

**Resource Breakdown**:
```yaml
# Lightweight services (30m CPU, 64Mi memory)
cart, catalogue, dispatch, payment, ratings, user, web

# Databases (50m CPU, 128-256Mi memory)
mongodb, mysql, rabbitmq, redis

# Java service (30m CPU, 256Mi memory)
shipping  # Needs more memory
```

## Deployment Process

### Automated Deployment:
```bash
cd /path/to/robot-shop-azure-platform

# Deploy with optimized values
helm upgrade --install robot-shop ./helm \
  --namespace robot-shop \
  --values ./helm/values-final.yaml
```

### Verification:
```bash
# Check all pods
kubectl get pods -n robot-shop

# Check services
kubectl get svc -n robot-shop

# Get web URL
kubectl get svc web -n robot-shop -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Results

### Before Fixes:
- ❌ 9/12 pods running
- ❌ 3 pods pending (redis, user, web)
- ❌ CPU utilization: 95-97% (overcommitted)
- ❌ Redis PVC stuck with wrong storage class

### After Fixes:
- ✅ 12/12 pods running
- ✅ All services healthy
- ✅ CPU utilization: ~65% (sustainable)
- ✅ Redis using Azure managed-csi storage
- ✅ Web accessible at LoadBalancer IP: 57.151.39.73:8080

## Autoscaling Configuration

### Cluster Autoscaler (Terraform):
```hcl
enable_autoscaling = true
min_node_count     = 2
max_node_count     = 5
```

### Future: Horizontal Pod Autoscaler (HPA):
Can be added to values file:
```yaml
web:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 70
```

## Key Learnings

1. **Always make Helm templates configurable** - Never hardcode resources
2. **Cloud-specific values** - Storage classes differ between AWS (gp2) and Azure (managed-csi)
3. **Resource planning** - Calculate total requests including system pods
4. **Incremental fixes** - Sed commands can leave orphaned lines, manual verification needed
5. **Service recreation** - LoadBalancer services may need Helm upgrade to recreate

## Maintenance

### To adjust resources:
1. Edit `helm/values-final.yaml`
2. Run: `helm upgrade robot-shop ./helm --namespace robot-shop --values ./helm/values-final.yaml`

### To add new service:
1. Ensure deployment template uses: `{{- with .Values.<service>.resources }}`
2. Add resource definition to values file
3. Deploy with Helm upgrade

## Files Reference

- **Templates**: `helm/templates/*-deployment.yaml`, `helm/templates/redis-statefulset.yaml`
- **Values**: `helm/values-final.yaml` (production), `helm/values-azure.yaml` (base)
- **Documentation**: This file (`HELM-FIXES-APPLIED.md`)
