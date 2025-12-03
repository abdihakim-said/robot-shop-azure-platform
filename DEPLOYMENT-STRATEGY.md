# Deployment Strategy - Monolithic vs Microservices

## Current Setup

You now have **TWO deployment options**:

### Option 1: Monolithic Deployment (Currently Running)
```bash
# Deploy all 12 services together
helm upgrade --install robot-shop ./helm \
  --namespace robot-shop \
  --values ./helm/values-dev.yaml
```

**Use when:**
- Initial deployment
- Full environment setup
- Testing all services together
- Simpler for demos

### Option 2: Per-Service Deployment (Best Practice)
```bash
# Deploy individual services
helm upgrade --install cart ./helm-charts/cart --namespace robot-shop
helm upgrade --install web ./helm-charts/web --namespace robot-shop
```

**Use when:**
- Updating a single service
- Independent service releases
- CI/CD pipelines
- Production deployments

---

## Migration Path

### Step 1: Keep Current Deployment Running
Your monolithic deployment is working fine. Don't touch it yet.

### Step 2: Test Per-Service Deployment (New Namespace)
```bash
# Test in a separate namespace
kubectl create namespace robot-shop-test

# Deploy services individually
helm install web ./helm-charts/web -n robot-shop-test
helm install cart ./helm-charts/cart -n robot-shop-test
# ... etc
```

### Step 3: When Ready, Switch to Per-Service
```bash
# Delete monolithic deployment
helm uninstall robot-shop -n robot-shop

# Deploy each service independently
for service in web cart catalogue user payment shipping ratings dispatch mongodb mysql redis rabbitmq; do
  helm install $service ./helm-charts/$service -n robot-shop
done
```

---

## CI/CD Pipeline Behavior

### Current Pipelines
Your pipelines are configured for **per-service deployments**:
- Each service has its own workflow
- Triggered when that service's code changes
- Deploys only that service

### What Happens Now
1. ✅ Pipelines will use `./helm-charts/<service>` 
2. ✅ Each service deploys independently
3. ✅ No conflicts with other services
4. ✅ True microservices architecture

---

## Recommendation

**For your interview:**

1. **Keep monolithic running now** - It's stable
2. **Explain both approaches** - Shows you understand trade-offs
3. **Demo per-service in test namespace** - Shows best practices
4. **Mention migration strategy** - Shows production thinking

**Key talking points:**
- "I started with monolithic for simplicity"
- "In production, we'd use per-service charts for independent deployments"
- "This allows different teams to own different services"
- "Reduces blast radius and enables faster releases"

---

## Quick Commands

### Deploy Everything (Monolithic)
```bash
helm upgrade --install robot-shop ./helm -n robot-shop --values ./helm/values-dev.yaml
```

### Deploy Single Service (Microservices)
```bash
helm upgrade --install cart ./helm-charts/cart -n robot-shop
```

### Check What's Deployed
```bash
# Monolithic
helm list -n robot-shop

# Per-service
helm list -n robot-shop --all
```

### Switch from Monolithic to Per-Service
```bash
# Backup current state
kubectl get all -n robot-shop -o yaml > backup.yaml

# Delete monolithic
helm uninstall robot-shop -n robot-shop

# Deploy per-service
for svc in web cart catalogue user payment shipping ratings dispatch mongodb mysql redis rabbitmq; do
  helm install $svc ./helm-charts/$svc -n robot-shop
done
```

---

## What You've Learned

✅ **Monolithic Helm Charts** - Simple, all-in-one deployment
✅ **Microservices Helm Charts** - Independent service deployments  
✅ **Migration Strategy** - How to transition between approaches
✅ **CI/CD Integration** - Per-service pipelines
✅ **Production Best Practices** - Industry-standard architecture

This is exactly what companies like Netflix, Uber, and Amazon do!
