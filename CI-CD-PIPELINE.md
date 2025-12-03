# Enterprise CI/CD Pipeline

## Overview

Production-grade CI/CD pipeline implementing continuous integration, continuous delivery, and GitOps principles with automated promotion across environments.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Flow                       │
└─────────────────────────────────────────────────────────────┘

Feature Branch
    ↓
Pull Request → CI Pipeline (Validate, Test, Scan)
    ↓
Merge to develop → Deploy to Dev (Automatic)
    ↓
Dev Success → Deploy to Staging (Automatic)
    ↓
Staging Success → Tag Release
    ↓
Push to main → Deploy to Production (Manual Approval)
```

## Pipelines

### 1. CI Pipeline (`ci.yml`)

**Purpose:** Continuous Integration - Quality Gates

**Triggers:**
- Pull requests to `main` or `develop`
- Push to `develop`

**Jobs:**

#### Validate Terraform
- Format check
- Syntax validation
- Configuration validation

#### Validate Helm
- Lint charts
- Template rendering (all environments)
- Syntax validation

#### Security Scan
- Trivy vulnerability scanning
- Configuration security checks
- SARIF report generation

#### Quality Gate
- All validations must pass
- Blocks merge if failures

**Purpose:** Prevents bad code from entering codebase

---

### 2. CD - Development (`cd-dev.yml`)

**Purpose:** Continuous Deployment to Dev

**Triggers:**
- Push to `develop` branch
- Manual dispatch

**Environment:** Development
- Auto-deploy (no approval)
- Fast feedback loop
- Testing ground

**Steps:**
1. Azure authentication
2. Get AKS credentials
3. Helm deployment (values-dev.yaml)
4. Verify all pods ready
5. Get application URL
6. Smoke test

**Success Criteria:**
- All pods running
- LoadBalancer accessible
- Smoke test passes

---

### 3. CD - Staging (`cd-staging.yml`)

**Purpose:** Automated Promotion to Staging

**Triggers:**
- Dev deployment success (automatic)
- Manual dispatch

**Environment:** Staging
- Requires dev success
- Production-like testing
- HPA enabled

**Steps:**
1. Wait for dev success
2. Deploy to staging
3. Verify deployment
4. Check HPA status
5. Integration tests

**Success Criteria:**
- All pods running
- HPA configured
- Integration tests pass

---

### 4. CD - Production (`cd-prod.yml`)

**Purpose:** Production Deployment with Approval

**Triggers:**
- Push to `main` branch
- Version tags (`v*`)
- Manual dispatch

**Environment:** Production
- **Requires manual approval**
- Backup before deployment
- Extended timeouts
- Comprehensive testing

**Steps:**
1. Manual approval gate
2. Backup current release
3. Deploy to production
4. Verify deployment (10 min timeout)
5. Check HPA status
6. Production smoke tests
7. Success notification

**Success Criteria:**
- All pods running
- HPA operational
- Smoke tests pass
- Zero downtime

---

### 5. Infrastructure (`infrastructure.yml`)

**Purpose:** Terraform Infrastructure Management

**Triggers:**
- PR (plan only)
- Push to main (apply)
- Manual dispatch

**Modes:**

#### Plan (PR)
- Shows infrastructure changes
- Multi-environment matrix
- Review before merge

#### Apply (Push/Manual)
- Applies infrastructure changes
- Environment-specific
- Requires approval for prod

**Environments:**
- Dev: Auto-apply
- Staging: Auto-apply
- Prod: Manual approval

---

## Branching Strategy

### GitFlow Model

```
main (production)
  ↓
develop (staging/dev)
  ↓
feature/* (development)
```

**Branches:**

- `main` - Production releases only
- `develop` - Integration branch
- `feature/*` - Feature development
- `hotfix/*` - Production fixes
- `release/*` - Release preparation

**Workflow:**

1. Create feature branch from `develop`
2. Develop and test locally
3. Create PR to `develop`
4. CI pipeline validates
5. Merge → Auto-deploy to dev
6. Dev success → Auto-deploy to staging
7. Create PR from `develop` to `main`
8. Merge → Deploy to production (with approval)

---

## Environment Strategy

| Environment | Branch | Deployment | Approval | HPA | Purpose |
|-------------|--------|------------|----------|-----|---------|
| Development | develop | Automatic | No | No | Fast iteration |
| Staging | develop | Automatic | No | Yes | Pre-prod testing |
| Production | main | Manual | Yes | Yes | Live traffic |

---

## Quality Gates

### Pre-Merge (CI)
- ✅ Terraform validation
- ✅ Helm validation
- ✅ Security scanning
- ✅ All checks pass

### Post-Deploy (CD)
- ✅ Pod health checks
- ✅ Service availability
- ✅ Smoke tests
- ✅ HPA verification (staging/prod)

---

## Deployment Safety

### Atomic Deployments
```yaml
--atomic  # Rollback on failure
--wait    # Wait for readiness
--timeout # Fail if too slow
```

### Rollback Strategy

**Automatic:**
- Failed deployment → Helm atomic rollback
- Pod crash loop → Previous version restored

**Manual:**
```bash
# Via Helm
helm rollback robot-shop -n robot-shop

# Via GitHub Actions
# Revert commit and push
git revert <commit>
git push origin main
```

### Blue-Green Ready
- LoadBalancer for zero-downtime
- HPA for gradual scaling
- Health checks before traffic

---

## Secrets Management

### Required Secrets

| Secret | Scope | Description |
|--------|-------|-------------|
| `AZURE_CREDENTIALS` | Dev | Service principal for dev |
| `AZURE_CREDENTIALS_STAGING` | Staging | Service principal for staging |
| `AZURE_CREDENTIALS_PROD` | Production | Service principal for prod |

### Setup

```bash
# Create service principal per environment
az ad sp create-for-rbac \
  --name "github-actions-robot-shop-dev" \
  --role contributor \
  --scopes /subscriptions/<SUB_ID>/resourceGroups/robot-shop-dev-rg \
  --sdk-auth

# Add to GitHub Secrets
# Settings → Secrets → Actions → New repository secret
```

---

## Environment Protection Rules

### Development
- No protection
- Auto-deploy
- Fast feedback

### Staging
- Wait for dev success
- Auto-deploy
- Integration testing

### Production
- **Required reviewers** (1-2 people)
- **Wait timer** (optional, e.g., 5 minutes)
- **Deployment branches** (main only)
- Manual approval required

**Setup:**
1. Go to Settings → Environments
2. Create `production` environment
3. Add required reviewers
4. Configure protection rules

---

## Monitoring & Observability

### Pipeline Monitoring

```bash
# View workflow runs
gh run list

# Watch specific workflow
gh run watch

# View logs
gh run view <run-id> --log
```

### Deployment Verification

```bash
# Check pods
kubectl get pods -n robot-shop

# Check HPA
kubectl get hpa -n robot-shop

# Check services
kubectl get svc -n robot-shop

# View logs
kubectl logs -f deployment/web -n robot-shop
```

---

## Best Practices Implemented

✅ **Separation of Concerns**
- CI validates quality
- CD handles deployment
- Infrastructure separate

✅ **Environment Progression**
- Dev → Staging → Production
- Automated promotion
- Manual approval for prod

✅ **Quality Gates**
- Pre-merge validation
- Post-deploy verification
- Security scanning

✅ **Safety Mechanisms**
- Atomic deployments
- Automatic rollback
- Backup before prod deploy

✅ **GitOps Principles**
- Git as source of truth
- Declarative configuration
- Automated sync

✅ **Security**
- Least privilege service principals
- Environment-specific credentials
- No secrets in code

✅ **Observability**
- Deployment logs
- Health checks
- Smoke tests

---

## Continuous Delivery vs Deployment

### Current Implementation: **Continuous Delivery**

- **Dev:** Continuous Deployment (fully automated)
- **Staging:** Continuous Deployment (automated after dev)
- **Production:** Continuous Delivery (manual approval)

**Why?**
- Production requires human oversight
- Compliance and safety
- Business approval needed

**To achieve full Continuous Deployment:**
- Add comprehensive automated testing
- Implement canary deployments
- Add automated rollback on metrics
- Remove manual approval (not recommended for prod)

---

## Usage Examples

### Deploy Feature to Dev

```bash
git checkout -b feature/new-feature
# Make changes
git commit -am "Add new feature"
git push origin feature/new-feature
# Create PR to develop
# CI runs automatically
# Merge → Auto-deploy to dev
```

### Promote to Production

```bash
# After staging validation
git checkout main
git merge develop
git tag v1.0.0
git push origin main --tags
# Manual approval required
# Deploy to production
```

### Rollback Production

```bash
# Option 1: Helm rollback
helm rollback robot-shop -n robot-shop

# Option 2: Git revert
git revert <bad-commit>
git push origin main
# Triggers new deployment
```

---

## Troubleshooting

### Pipeline Fails at Azure Login
**Issue:** Invalid credentials
**Fix:** Regenerate service principal, update secret

### Deployment Timeout
**Issue:** Pods not ready in time
**Fix:** Check pod logs, increase timeout, fix resource issues

### Staging Not Triggered
**Issue:** Dev deployment failed
**Fix:** Fix dev issues first, staging waits for dev success

### Production Approval Stuck
**Issue:** No reviewers configured
**Fix:** Add reviewers in environment settings

---

## Metrics & KPIs

### Deployment Frequency
- Dev: Multiple times per day
- Staging: Daily
- Production: Weekly/on-demand

### Lead Time
- Feature to dev: < 1 hour
- Dev to staging: < 30 minutes
- Staging to prod: < 1 day (with approval)

### Change Failure Rate
- Target: < 15%
- Atomic rollback reduces impact

### Mean Time to Recovery
- Automatic rollback: < 5 minutes
- Manual rollback: < 15 minutes

---

## Future Enhancements

- [ ] Add ArgoCD for GitOps
- [ ] Implement canary deployments
- [ ] Add automated performance testing
- [ ] Integrate with Datadog
- [ ] Add Slack notifications
- [ ] Implement feature flags
- [ ] Add chaos engineering tests

---

## Summary

✅ **Enterprise-grade CI/CD**
✅ **Multi-environment with promotion**
✅ **Automated quality gates**
✅ **Production safety mechanisms**
✅ **GitOps principles**
✅ **Continuous delivery achieved**

**Status:** Production-ready, interview-ready, enterprise-standard
