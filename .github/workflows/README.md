# CI/CD Pipelines

## Available Workflows

### 1. Infrastructure Pipeline (DevSecOps)
**File:** `infrastructure.yml`  
**Trigger:** Push/PR to terraform files

**What it does:**
- ✅ Security scanning (tfsec, Checkov)
- ✅ Terraform validation
- ✅ Auto-deploy to dev (on develop branch)
- ✅ Auto-deploy to staging (on release/* branches)
- ✅ Manual approval for production (on main branch)

**Branch Strategy:**
```
develop → Auto-deploy to dev
release/* → Auto-deploy to staging
main → Manual approval → production
```

---

### 2. Build & Push (Application)
**File:** `build-and-push.yml`  
**Trigger:** Push to service directories

**What it does:**
- ✅ Secret scanning (TruffleHog)
- ✅ Dependency scanning (Trivy)
- ✅ SAST scanning (Semgrep)
- ✅ Build Docker images
- ✅ Container scanning
- ✅ Push to ACR
- ✅ SBOM generation

---

### 3. Test Environments (Auto-Destroy)
**File:** `test-environments.yml`  
**Trigger:** Manual (workflow_dispatch)

**What it does:**
- ✅ Deploy staging/production
- ✅ Wait specified duration
- ✅ Auto-destroy after time limit
- ✅ Calculate cost

**Usage:**
```bash
# Via GitHub UI:
Actions → Test Environments → Run workflow
  - Environment: staging/production/both
  - Duration: 10 minutes
  - Skip destroy: false

# Cost for 10 minutes:
Staging: ~$0.10
Production: ~$0.24
Both: ~$0.34
```

**Perfect for:**
- Taking screenshots
- Recording demos
- Testing before interviews
- Quick validation

---

### 4. PR Validation
**File:** `pr-validation.yml`  
**Trigger:** Pull requests

**What it does:**
- ✅ Run all security scans
- ✅ Validate code quality
- ✅ Check for vulnerabilities
- ✅ Block merge if CRITICAL issues

---

### 5. Deploy Service
**File:** `deploy-service.yml`  
**Trigger:** Called by other workflows

**What it does:**
- ✅ Deploy specific service to AKS
- ✅ Update Helm values
- ✅ Verify deployment

---

## Quick Commands

### Test Staging for 10 Minutes
```bash
# Via GitHub CLI
gh workflow run test-environments.yml \
  -f environment=staging \
  -f duration_minutes=10

# Via UI
Actions → Test Environments → Run workflow
```

### Deploy Infrastructure Changes
```bash
# Dev
git checkout develop
git add terraform/
git commit -m "Update infrastructure"
git push  # Auto-deploys to dev

# Staging
git checkout -b release/v1.0.0
git push  # Auto-deploys to staging

# Production
git checkout main
git merge release/v1.0.0
git push  # Requires manual approval
```

### Build & Deploy Application
```bash
# Make changes to service
git add cart/
git commit -m "Update cart service"
git push  # Auto-builds and scans

# Only changed services are built
```

---

## Cost Control

### Auto-Destroy Feature
All test deployments auto-destroy after specified time:
- ✅ No forgotten resources
- ✅ Predictable costs
- ✅ Safe testing

### Manual Override
Set `skip_destroy: true` to keep environment running:
- ⚠️ Remember to manually destroy
- ⚠️ Costs continue until destroyed

### Destroy Manually
```bash
cd terraform/environments/staging
terraform destroy -auto-approve
```

---

## Security Features

### Infrastructure Security
- tfsec: Terraform security scanning
- Checkov: Policy-as-code validation
- SARIF reports to GitHub Security

### Application Security
- TruffleHog: Secret detection
- Trivy: Dependency + container scanning
- Semgrep: SAST code analysis
- Security gate: Blocks CRITICAL vulnerabilities

---

## Environment Protection Rules

### Development
- ✅ Auto-deploy on push
- ✅ No approval required
- ✅ Fast iteration

### Staging
- ✅ Auto-deploy on release branch
- ✅ No approval required
- ✅ Production parity testing

### Production
- ⚠️ Manual approval required
- ⚠️ Protected branch (main)
- ⚠️ All security checks must pass

---

## Monitoring

### Pipeline Status
```bash
# View recent runs
gh run list --limit 10

# View specific run
gh run view <run-id>

# Watch live
gh run watch
```

### Cost Tracking
Each test run shows estimated cost in summary:
- Duration
- Hourly rate
- Total cost

---

## Troubleshooting

### Pipeline Fails on Security Scan
1. Check GitHub Security tab
2. Fix vulnerabilities
3. Re-run pipeline

### Terraform Apply Fails
1. Check Azure credentials
2. Verify resource quotas
3. Check for naming conflicts

### Auto-Destroy Doesn't Run
1. Check workflow logs
2. Verify `skip_destroy` is false
3. Manually destroy if needed

---

## Best Practices

✅ **Always use auto-destroy for testing**  
✅ **Review security findings before merging**  
✅ **Test in staging before production**  
✅ **Monitor costs with budget alerts**  
✅ **Use manual approval for production**

---

## Next Steps

1. Set up Azure credentials in GitHub Secrets
2. Configure environment protection rules
3. Test with staging deployment
4. Document any customizations
