# Build Once, Deploy Many - DevSecOps Pattern

## Overview

Industry-standard pattern where container images are built once, scanned for security, and deployed to multiple environments without rebuilding.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Build Once, Deploy Many Flow                    │
└─────────────────────────────────────────────────────────────┘

Code Change (web/)
    ↓
Push to develop
    ↓
Build Image (ONCE)
    ├─ Tag: abc123 (commit SHA)
    ├─ Push to ACR
    ├─ Security Scan (Trivy)
    └─ Tag: tested-abc123
    ↓
Deploy to Dev (image: abc123)
    ↓
Deploy to Staging (SAME image: abc123)
    ↓
Deploy to Production (SAME image: abc123)

✅ Same artifact tested in all environments
```

## Why Build Once?

### ❌ Build Multiple Times (Bad)

```
Develop  → Build #1 → Deploy to dev
Release  → Build #2 → Deploy to staging
Main     → Build #3 → Deploy to prod

Problems:
- Different images per environment
- What you test ≠ what you deploy
- Slower (rebuild each time)
- Security scans repeated
- Inconsistent artifacts
```

### ✅ Build Once (Best Practice)

```
Develop → Build #1 (tag: abc123)
          ↓
       Push to ACR
          ↓
       Security Scan
          ↓
Deploy abc123 to dev
Deploy abc123 to staging
Deploy abc123 to prod

Benefits:
- Same image everywhere
- What you test = what you deploy
- Faster deployments
- Security scan once
- Immutable artifacts
```

---

## Pipeline Flow

### 1. Build & Push Pipeline

**Trigger:** Push to develop/release/main

```yaml
# .github/workflows/build-and-push.yml

detect-changes:
  # Detect which services changed
  # Output: ["web", "cart"]

build-and-push:
  # For each changed service:
  # 1. Build Docker image
  # 2. Tag with commit SHA
  # 3. Push to ACR
  # 4. Security scan with Trivy
  # 5. Tag as "tested-{SHA}"
```

**Image Tags:**
```
robotshopdevacrmtttm8.azurecr.io/web:abc123
robotshopdevacrmtttm8.azurecr.io/web:tested-abc123
robotshopdevacrmtttm8.azurecr.io/web:latest
```

---

### 2. Deploy Pipeline

**Trigger:** After build completes

```yaml
# .github/workflows/service-web.yml

wait-for-build:
  # Wait for build-and-push to complete

deploy-dev:
  # Deploy image abc123 to dev
  uses: reusable-service-cd.yml
  with:
    image-tag: abc123

deploy-staging:
  # Deploy SAME image abc123 to staging
  uses: reusable-service-cd.yml
  with:
    image-tag: abc123

deploy-prod:
  # Deploy SAME image abc123 to prod
  uses: reusable-service-cd.yml
  with:
    image-tag: abc123
```

---

## DevSecOps Integration

### Security Scanning (Shift Left)

```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.ACR_LOGIN_SERVER }}/web:${{ github.sha }}
    format: 'sarif'
```

**What Trivy Scans:**
- OS vulnerabilities
- Application dependencies
- Misconfigurations
- Secrets in images
- License compliance

**Results:**
- Uploaded to GitHub Security tab
- Blocks deployment if critical vulnerabilities
- SARIF format for integration

---

## Image Tagging Strategy

### Commit SHA as Tag

```bash
# Commit: abc123def456
# Image tag: abc123def456

Benefits:
- Unique per commit
- Traceable to code
- Immutable
- Easy rollback
```

### Multiple Tags

```
web:abc123           # Specific version
web:tested-abc123    # Passed security scan
web:latest           # Latest build
web:v1.0.0           # Release version
```

---

## Deployment Verification

### Image Tag Verification

```yaml
- name: Verify deployment
  run: |
    DEPLOYED_IMAGE=$(kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}')
    
    if [[ "$DEPLOYED_IMAGE" != *"abc123"* ]]; then
      echo "ERROR: Wrong image deployed!"
      exit 1
    fi
```

**Ensures:**
- Correct image deployed
- No accidental latest tag
- Traceability

---

## Real-World Example

### Scenario: Update Web Service

```bash
# 1. Developer makes change
git checkout -b feature/web-ui-update
cd web/
# ... code changes ...
git commit -m "feat(web): new UI"
git push origin feature/web-ui-update
```

**What Happens:**
```
PR Created
  ↓
CI runs (lint, test)
  ↓
Merge to develop
  ↓
Build Pipeline Triggers
  ├─ Build image
  ├─ Tag: abc123
  ├─ Push to ACR
  ├─ Trivy scan
  └─ Tag: tested-abc123
  ↓
Deploy Pipeline Triggers
  └─ Deploy abc123 to dev
```

```bash
# 2. Create release
git checkout -b release/v1.0.0
git push origin release/v1.0.0
```

**What Happens:**
```
Build Pipeline (if changes)
  ├─ Build image
  └─ Tag: def456
  ↓
Deploy Pipeline
  └─ Deploy def456 to staging
     (SAME image, no rebuild)
```

```bash
# 3. Deploy to production
git checkout main
git merge release/v1.0.0
git push origin main
```

**What Happens:**
```
Deploy Pipeline
  └─ Deploy def456 to production
     (SAME image tested in dev & staging)
```

---

## Benefits

### 1. Consistency
✅ Same artifact in all environments
✅ What you test is what you deploy
✅ No "works in staging but not prod"

### 2. Speed
✅ Build once (5 min)
✅ Deploy many (1 min each)
✅ No rebuild wait time

### 3. Security
✅ Scan once
✅ Immutable artifacts
✅ Traceable to commit

### 4. Reliability
✅ Tested artifact promoted
✅ No build variations
✅ Easy rollback (same image)

### 5. Compliance
✅ Audit trail (image tags)
✅ Security scan results
✅ Deployment history

---

## Rollback Strategy

### Rollback to Previous Image

```bash
# Find previous image tag
kubectl get deployment web -n robot-shop -o yaml | grep image:

# Rollback via Helm
helm rollback web -n robot-shop

# Or deploy specific image
helm upgrade web ./helm \
  --set web.image.tag=previous-sha \
  --namespace robot-shop
```

**Benefit:** Instant rollback (no rebuild)

---

## Image Lifecycle

```
Build → Scan → Test (dev) → Test (staging) → Prod → Archive

Day 0:  abc123 built
Day 0:  abc123 → dev
Day 1:  abc123 → staging
Day 2:  abc123 → prod
Day 30: abc123 archived (retention policy)
```

---

## ACR Configuration

### Image Retention

```bash
# Keep images for 30 days
az acr config retention update \
  --name robotshopdevacrmtttm8 \
  --days 30 \
  --type UntaggedManifests
```

### Image Scanning

```bash
# Enable Defender for Containers
az security pricing create \
  --name ContainerRegistry \
  --tier Standard
```

---

## Comparison: Before vs After

### Before (Build Multiple Times)

| Aspect | Time | Risk | Cost |
|--------|------|------|------|
| Build dev | 5 min | Medium | $ |
| Build staging | 5 min | Medium | $ |
| Build prod | 5 min | High | $ |
| **Total** | **15 min** | **High** | **$$$** |

### After (Build Once)

| Aspect | Time | Risk | Cost |
|--------|------|------|------|
| Build once | 5 min | Low | $ |
| Deploy dev | 1 min | Low | - |
| Deploy staging | 1 min | Low | - |
| Deploy prod | 1 min | Low | - |
| **Total** | **8 min** | **Low** | **$** |

**Savings:** 47% faster, 67% cost reduction

---

## Best Practices Implemented

✅ **Immutable Artifacts**
- Images never change after build
- Tagged with commit SHA
- Traceable to source code

✅ **Security Scanning**
- Trivy scan on every build
- SARIF reports to GitHub
- Blocks critical vulnerabilities

✅ **Environment Parity**
- Same image in all environments
- Consistent behavior
- Predictable deployments

✅ **Fast Deployments**
- No rebuild wait
- Pull from registry
- 1-minute deploys

✅ **Easy Rollback**
- Previous images available
- Instant rollback
- No rebuild needed

✅ **Audit Trail**
- Image tags = commit SHAs
- Deployment history
- Security scan results

---

## DevSecOps Checklist

✅ **Build Phase**
- [x] Dockerfile linting (Hadolint)
- [x] Image vulnerability scanning (Trivy)
- [x] SARIF report generation
- [x] Security gate (block on critical)

✅ **Deploy Phase**
- [x] Image tag verification
- [x] Deployment validation
- [x] Smoke tests
- [x] Rollback capability

✅ **Runtime Phase**
- [ ] Runtime security (Falco)
- [ ] Network policies
- [ ] Pod security standards
- [ ] Secret management (Key Vault)

---

## Summary

✅ **Build Once** - Single build per commit
✅ **Deploy Many** - Same image to all environments
✅ **DevSecOps** - Security scanning integrated
✅ **Immutable** - Images never change
✅ **Traceable** - Commit SHA as tag
✅ **Fast** - 47% faster than rebuild
✅ **Reliable** - What you test = what you deploy

**Status:** Industry-standard pattern, production-ready
