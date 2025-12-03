# GitFlow Environment Mapping Test

## ✅ Fixed Implementation

**Branch → Environment Mapping:**
- `develop` → **dev** (auto-deploy)
- `release/*` → **staging** (auto-deploy)
- `main` → **production** (requires approval)

## 🧪 Test Plan

### Test 1: Develop → Dev
```bash
git checkout develop
echo "test" >> cart/test.txt
git add . && git commit -m "test: dev deployment"
git push origin develop
# Expected: Deploys to dev environment
```

### Test 2: Release → Staging
```bash
git checkout -b release/v1.0.0
git push origin release/v1.0.0
# Expected: Deploys to staging environment
```

### Test 3: Main → Production
```bash
git checkout main
git merge release/v1.0.0
git push origin main
# Expected: Waits for manual approval, then deploys to production
```

## 📊 Verification

Check workflow runs:
```bash
gh run list --repo abdihakim-said/robot-shop-azure-platform --limit 5
```

Check deployed environment:
```bash
# Dev
kubectl get pods -n robot-shop --context robot-shop-dev-aks

# Staging
kubectl get pods -n robot-shop --context robot-shop-staging-aks

# Production
kubectl get pods -n robot-shop --context robot-shop-prod-aks
```
