# CI/CD Implementation Guide

## Prerequisites Checklist

Before implementing CI/CD, ensure you have:

- [ ] GitHub repository created
- [ ] Azure subscription active
- [ ] Azure CLI installed and logged in
- [ ] kubectl configured
- [ ] Terraform applied (infrastructure running)

---

## Step 1: Setup GitHub Repository

### 1.1 Create Repository

```bash
# Initialize git (if not already)
cd /path/to/robot-shop-azure-platform
git init
git add .
git commit -m "Initial commit: Enterprise microservices platform"

# Create GitHub repo and push
gh repo create robot-shop-azure-platform --public --source=. --remote=origin --push

# Or manually:
# 1. Go to github.com
# 2. Create new repository: robot-shop-azure-platform
# 3. Push code
git remote add origin https://github.com/YOUR_USERNAME/robot-shop-azure-platform.git
git branch -M main
git push -u origin main
```

### 1.2 Create Branches

```bash
# Create develop branch
git checkout -b develop
git push -u origin develop

# Set develop as default branch for PRs (optional)
# GitHub → Settings → Branches → Default branch → develop
```

---

## Step 2: Configure Azure Service Principal

### 2.1 Create Service Principal for Dev

```bash
# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal for dev
az ad sp create-for-rbac \
  --name "github-actions-robot-shop-dev" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/robot-shop-dev-rg \
  --sdk-auth

# Save the JSON output - you'll need it for GitHub Secrets
```

**Output will look like:**
```json
{
  "clientId": "xxx",
  "clientSecret": "xxx",
  "subscriptionId": "xxx",
  "tenantId": "xxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### 2.2 Create Service Principals for Staging & Prod (Optional)

```bash
# For staging (when you create staging environment)
az ad sp create-for-rbac \
  --name "github-actions-robot-shop-staging" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/robot-shop-staging-rg \
  --sdk-auth

# For production (when you create prod environment)
az ad sp create-for-rbac \
  --name "github-actions-robot-shop-prod" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/robot-shop-prod-rg \
  --sdk-auth
```

---

## Step 3: Configure GitHub Secrets

### 3.1 Add Secrets to GitHub

Go to: **GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CREDENTIALS` | JSON from Step 2.1 | Dev environment credentials |
| `AZURE_CREDENTIALS_STAGING` | JSON from Step 2.2 | Staging credentials (optional) |
| `AZURE_CREDENTIALS_PROD` | JSON from Step 2.2 | Prod credentials (optional) |

**Via GitHub CLI:**
```bash
# Add dev credentials
gh secret set AZURE_CREDENTIALS < azure-creds-dev.json

# Add staging credentials (optional)
gh secret set AZURE_CREDENTIALS_STAGING < azure-creds-staging.json

# Add prod credentials (optional)
gh secret set AZURE_CREDENTIALS_PROD < azure-creds-prod.json
```

---

## Step 4: Configure GitHub Environments

### 4.1 Create Environments

Go to: **GitHub Repository → Settings → Environments**

Create three environments:

#### Development Environment
- Name: `development`
- Protection rules: None (auto-deploy)

#### Staging Environment
- Name: `staging`
- Protection rules: None (auto-deploy)

#### Production Environment
- Name: `production`
- Protection rules:
  - ✅ Required reviewers (add yourself)
  - ✅ Wait timer: 5 minutes (optional)
  - ✅ Deployment branches: `main` only

---

## Step 5: Test CI/CD Workflows

### 5.1 Test CI Pipeline (Pull Request)

```bash
# Create feature branch
git checkout develop
git checkout -b feature/test-ci

# Make a small change
echo "# Test CI" >> test-ci.md
git add test-ci.md
git commit -m "test: CI pipeline"
git push origin feature/test-ci

# Create PR on GitHub
gh pr create --base develop --title "Test CI Pipeline" --body "Testing CI workflow"

# Check workflow
gh run list
gh run watch
```

**Expected Result:**
- ✅ CI workflow runs
- ✅ Terraform validation passes
- ✅ Helm validation passes
- ✅ Security scan completes

### 5.2 Test Build Pipeline

```bash
# Merge PR to develop
gh pr merge --merge

# Or via GitHub UI
# This triggers build-and-push.yml

# Check workflow
gh run list --workflow=build-and-push.yml
gh run watch

# Verify image in ACR
az acr repository list --name robotshopdevacrmtttm8 --output table
```

**Expected Result:**
- ✅ Build workflow runs
- ✅ Images built and pushed to ACR
- ✅ Trivy scan completes
- ✅ Images tagged with commit SHA

### 5.3 Test Deploy to Dev

```bash
# Already triggered by merge to develop
# Check deployment workflow
gh run list --workflow=service-web.yml

# Verify deployment
kubectl get pods -n robot-shop
kubectl get svc web -n robot-shop
```

**Expected Result:**
- ✅ Deploy workflow runs
- ✅ Pods updated with new image
- ✅ Service accessible

---

## Step 6: Test Full Promotion Flow

### 6.1 Dev → Staging → Prod

```bash
# 1. Create release branch
git checkout develop
git checkout -b release/v1.0.0
git push origin release/v1.0.0

# Check staging deployment
gh run list --workflow=service-web.yml
kubectl get pods -n robot-shop  # (if staging cluster exists)

# 2. Merge to main for production
git checkout main
git merge release/v1.0.0
git tag v1.0.0
git push origin main --tags

# 3. Approve production deployment
# Go to GitHub → Actions → Select workflow run → Review deployments → Approve

# Check production deployment
gh run list --workflow=service-web.yml
```

---

## Step 7: Verify CI/CD is Working

### 7.1 Check Workflow Status

```bash
# List all workflow runs
gh run list

# Watch specific workflow
gh run watch <run-id>

# View logs
gh run view <run-id> --log
```

### 7.2 Check Deployments

```bash
# Check pods
kubectl get pods -n robot-shop

# Check images
kubectl get pods -n robot-shop -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n'

# Verify image tags match commit SHA
git rev-parse HEAD
```

### 7.3 Check ACR Images

```bash
# List repositories
az acr repository list --name robotshopdevacrmtttm8 --output table

# List tags for web service
az acr repository show-tags \
  --name robotshopdevacrmtttm8 \
  --repository web \
  --output table
```

---

## Troubleshooting

### Issue: Workflow Not Triggering

**Check:**
```bash
# Verify workflows exist
ls -la .github/workflows/

# Check branch
git branch --show-current

# Verify push
git log --oneline -5
```

**Fix:**
- Ensure workflows are in `.github/workflows/`
- Ensure you're on correct branch (develop/main)
- Check workflow triggers in YAML files

### Issue: Azure Authentication Failed

**Check:**
```bash
# Verify secret exists
gh secret list

# Test service principal locally
az login --service-principal \
  --username <clientId> \
  --password <clientSecret> \
  --tenant <tenantId>
```

**Fix:**
- Recreate service principal
- Update GitHub secret
- Verify resource group exists

### Issue: Image Not Found

**Check:**
```bash
# Verify ACR exists
az acr show --name robotshopdevacrmtttm8

# Check if image was pushed
az acr repository show-tags \
  --name robotshopdevacrmtttm8 \
  --repository web
```

**Fix:**
- Ensure build workflow completed
- Check ACR permissions
- Verify image tag in deployment

### Issue: Deployment Timeout

**Check:**
```bash
# Check pod status
kubectl describe pod <pod-name> -n robot-shop

# Check events
kubectl get events -n robot-shop --sort-by='.lastTimestamp'
```

**Fix:**
- Increase timeout in workflow
- Check resource constraints
- Verify image pull secrets

---

## Monitoring CI/CD

### GitHub Actions Dashboard

```bash
# View all runs
gh run list

# View specific workflow
gh run list --workflow=service-web.yml

# Watch live
gh run watch
```

### Workflow Badges

Add to README:
```markdown
![CI](https://github.com/YOUR_USERNAME/robot-shop-azure-platform/workflows/CI%20-%20Continuous%20Integration/badge.svg)
![Build](https://github.com/YOUR_USERNAME/robot-shop-azure-platform/workflows/Build%20%26%20Push%20Images/badge.svg)
```

---

## Testing Checklist

- [ ] CI workflow runs on PR
- [ ] Build workflow creates images
- [ ] Images pushed to ACR
- [ ] Trivy scan completes
- [ ] Deploy to dev works
- [ ] Deploy to staging works (if exists)
- [ ] Production approval required
- [ ] Deploy to prod works
- [ ] Rollback works
- [ ] All 12 services deploy independently

---

## Next Steps

1. **Test Each Service Independently**
   ```bash
   # Change only cart service
   cd cart/
   # Make change
   git commit -m "feat(cart): update"
   git push
   # Verify only cart pipeline runs
   ```

2. **Test Rollback**
   ```bash
   # Rollback via Helm
   helm rollback web -n robot-shop
   ```

3. **Monitor Deployments**
   ```bash
   # Watch pods
   kubectl get pods -n robot-shop -w
   
   # Check logs
   kubectl logs -f deployment/web -n robot-shop
   ```

---

## Summary

✅ **Setup Complete When:**
- GitHub repository created
- Service principals configured
- GitHub secrets added
- Environments configured
- Workflows tested and working
- Images building and deploying
- All services accessible

**Time Required:** 30-60 minutes for full setup

**Result:** Fully automated CI/CD pipeline with GitFlow branching
