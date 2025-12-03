# Enterprise GitFlow & Microservices CI/CD

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│         Enterprise Microservices CI/CD Pipeline              │
└─────────────────────────────────────────────────────────────┘

12 Microservices (Independent Pipelines)
    ↓
GitFlow Branching Strategy
    ↓
Environment Promotion (Dev → Staging → Prod)
    ↓
Reusable Workflows (DRY Principle)
```

## GitFlow Branching Strategy

### Branch Structure

```
main (production)
  ↓
release/v1.0.0 (staging)
  ↓
develop (development)
  ↓
feature/service-name-feature (feature development)
hotfix/critical-fix (production fixes)
```

### Branch Purposes

| Branch | Environment | Purpose | Lifetime |
|--------|-------------|---------|----------|
| `main` | Production | Live releases | Permanent |
| `release/*` | Staging | Release candidates | Temporary |
| `develop` | Development | Integration | Permanent |
| `feature/*` | Local | Feature development | Temporary |
| `hotfix/*` | Production | Critical fixes | Temporary |

---

## Workflow: Feature Development

### 1. Create Feature Branch

```bash
# From develop
git checkout develop
git pull origin develop
git checkout -b feature/web-new-ui

# Make changes to web service
cd web/
# ... code changes ...

git add .
git commit -m "feat(web): add new UI components"
git push origin feature/web-new-ui
```

### 2. Create Pull Request

```bash
# Create PR: feature/web-new-ui → develop
# CI Pipeline runs automatically:
# - Validates web service
# - Runs tests
# - Security scan
# - Quality gate
```

### 3. Merge to Develop

```bash
# After PR approval
git checkout develop
git merge feature/web-new-ui
git push origin develop

# Triggers: Auto-deploy web service to DEV
```

---

## Workflow: Release to Staging

### 1. Create Release Branch

```bash
# From develop (when ready for staging)
git checkout develop
git checkout -b release/v1.0.0

# Update version
echo "v1.0.0" > VERSION

git add VERSION
git commit -m "chore: bump version to v1.0.0"
git push origin release/v1.0.0

# Triggers: Auto-deploy ALL services to STAGING
```

### 2. Test in Staging

```bash
# Staging environment with:
# - Production-like resources
# - HPA enabled
# - Integration tests
# - Performance tests
```

### 3. Fix Bugs (if needed)

```bash
# On release branch
git checkout release/v1.0.0

# Fix bugs
git commit -m "fix(cart): resolve checkout issue"
git push origin release/v1.0.0

# Triggers: Re-deploy cart service to STAGING
```

---

## Workflow: Production Deployment

### 1. Merge to Main

```bash
# After staging validation
git checkout main
git merge release/v1.0.0
git tag v1.0.0
git push origin main --tags

# Triggers: Deploy to PRODUCTION (requires approval)
```

### 2. Manual Approval

```
GitHub → Actions → Approve production deployment
↓
Deployment starts
↓
All services deployed to production
```

### 3. Merge Back to Develop

```bash
# Keep develop in sync
git checkout develop
git merge main
git push origin develop
```

---

## Workflow: Hotfix

### 1. Create Hotfix Branch

```bash
# From main (production issue)
git checkout main
git checkout -b hotfix/payment-critical-bug

# Fix the issue
cd payment/
# ... fix code ...

git commit -m "fix(payment): resolve critical payment bug"
git push origin hotfix/payment-critical-bug
```

### 2. Deploy Hotfix

```bash
# Merge to main
git checkout main
git merge hotfix/payment-critical-bug
git tag v1.0.1
git push origin main --tags

# Triggers: Deploy payment service to PRODUCTION
```

### 3. Merge Back

```bash
# Merge to develop
git checkout develop
git merge hotfix/payment-critical-bug
git push origin develop
```

---

## Microservices Pipeline Structure

### Per-Service Pipelines (12 services)

```
service-web.yml
service-cart.yml
service-catalogue.yml
service-user.yml
service-payment.yml
service-shipping.yml
service-ratings.yml
service-dispatch.yml
service-mongodb.yml (stateful)
service-mysql.yml (stateful)
service-redis.yml (stateful)
service-rabbitmq.yml (stateful)
```

### Reusable Workflows (DRY)

```
reusable-service-ci.yml   (Quality gates)
reusable-service-cd.yml   (Deployment)
```

---

## Pipeline Triggers

### Per Service

| Event | Branch | Action |
|-------|--------|--------|
| PR | Any | Run CI (validate, test, scan) |
| Push | `develop` | Deploy to Dev |
| Push | `release/*` | Deploy to Staging |
| Push | `main` | Deploy to Production (approval) |

### Example: Web Service Change

```
1. Change web/index.html
2. Push to feature/web-update
3. Create PR to develop
4. CI runs for web service only
5. Merge → Deploy web to dev
6. Other services unaffected
```

---

## Environment Promotion Flow

```
┌──────────────┐
│ Feature      │
│ Branch       │
└──────┬───────┘
       │ PR + CI
       ↓
┌──────────────┐
│ Develop      │ → Auto-deploy to DEV
│ Branch       │
└──────┬───────┘
       │ Create release branch
       ↓
┌──────────────┐
│ Release      │ → Auto-deploy to STAGING
│ Branch       │
└──────┬───────┘
       │ Merge to main
       ↓
┌──────────────┐
│ Main         │ → Manual approval → PRODUCTION
│ Branch       │
└──────────────┘
```

---

## Independent Service Deployment

### Scenario: Update Only Cart Service

```bash
# 1. Feature development
git checkout -b feature/cart-optimization
# Change only cart/ directory
git push origin feature/cart-optimization

# 2. PR to develop
# Only cart CI pipeline runs

# 3. Merge to develop
# Only cart deploys to dev
# Web, catalogue, etc. unchanged

# 4. Release
git checkout -b release/v1.1.0
git push origin release/v1.1.0
# Only cart deploys to staging

# 5. Production
git checkout main
git merge release/v1.1.0
# Only cart deploys to production
```

**Result:** Zero downtime, independent releases

---

## Best Practices Implemented

### 1. GitFlow Strategy
✅ Clear branch purposes
✅ Environment mapping
✅ Release management
✅ Hotfix support

### 2. Microservices Independence
✅ Per-service pipelines
✅ Independent deployments
✅ Service-specific CI/CD
✅ No monolithic releases

### 3. Reusable Workflows
✅ DRY principle
✅ Consistent quality gates
✅ Easy maintenance
✅ Scalable to 100s of services

### 4. Environment Promotion
✅ Dev → Staging → Prod
✅ Automated progression
✅ Manual approval for prod
✅ Rollback capability

### 5. Quality Gates
✅ Automated testing
✅ Security scanning
✅ Code validation
✅ Smoke tests

### 6. Safety Mechanisms
✅ Atomic deployments
✅ Automatic rollback
✅ Health checks
✅ Approval gates

---

## Real-World Company Patterns

### Netflix Pattern
- Microservices with independent pipelines ✅
- Spinnaker for multi-cloud deployment
- Canary deployments
- Chaos engineering

### Uber Pattern
- Monorepo with microservices ✅
- Service mesh (Istio)
- Feature flags
- A/B testing

### Amazon Pattern
- Two-pizza teams own services ✅
- Independent release cycles ✅
- Service-level SLAs
- Automated rollback

**Our Implementation:** Hybrid of all three patterns

---

## Commands Cheat Sheet

### Start New Feature
```bash
git checkout develop
git pull
git checkout -b feature/service-name-feature
```

### Deploy to Dev
```bash
git push origin develop
# Auto-deploys changed services
```

### Create Release
```bash
git checkout -b release/v1.0.0
git push origin release/v1.0.0
# Auto-deploys to staging
```

### Deploy to Production
```bash
git checkout main
git merge release/v1.0.0
git tag v1.0.0
git push origin main --tags
# Requires approval → deploys to prod
```

### Hotfix
```bash
git checkout main
git checkout -b hotfix/critical-fix
# Fix and commit
git checkout main
git merge hotfix/critical-fix
git push origin main
```

---

## Monitoring Deployments

### Check Pipeline Status
```bash
# Via GitHub CLI
gh run list --workflow=service-web.yml
gh run watch
```

### Check Service Status
```bash
# Dev
kubectl get pods -n robot-shop -l service=web

# Staging
kubectl get pods -n robot-shop -l service=web --context=staging

# Production
kubectl get pods -n robot-shop -l service=web --context=production
```

---

## Rollback Strategies

### Service-Level Rollback
```bash
# Rollback specific service
helm rollback web -n robot-shop

# Or via Git
git revert <commit>
git push origin main
```

### Full Environment Rollback
```bash
# Revert to previous release
git checkout main
git revert <release-commit>
git push origin main
```

---

## Advantages Over Monolithic CI/CD

| Aspect | Monolithic | Microservices (Ours) |
|--------|-----------|---------------------|
| Deployment Speed | Slow (all services) | Fast (one service) |
| Risk | High (all or nothing) | Low (isolated) |
| Rollback | All services | Single service |
| Team Independence | Blocked | Independent |
| Release Frequency | Weekly | Multiple per day |
| Blast Radius | Entire app | Single service |

---

## Summary

✅ **12 independent service pipelines**
✅ **GitFlow branching strategy**
✅ **3-tier environment promotion**
✅ **Reusable workflows (DRY)**
✅ **Automated quality gates**
✅ **Manual approval for production**
✅ **Independent service deployments**
✅ **Enterprise-grade patterns**

**Status:** Production-ready, follows Netflix/Uber/Amazon patterns
