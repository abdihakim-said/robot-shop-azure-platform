# DevSecOps Pipeline - Robot Shop

## Overview

This project implements a comprehensive DevSecOps pipeline with security integrated at every stage of the CI/CD process.

---

## Security Scanning Stages

### 1. **Pre-Build Security** (Before Docker Build)

#### Secret Detection
- **Tool:** TruffleHog
- **What it scans:** Hardcoded secrets, API keys, passwords
- **Languages:** All
- **When:** On every push
- **Action:** Warns if secrets found

#### Dependency Vulnerability Scanning
- **Tool:** Trivy (filesystem scan)
- **What it scans:** Package dependencies for known vulnerabilities
- **Languages:** Node.js (npm), Python (pip), Java (maven), Go (go.mod), PHP (composer)
- **Severity:** CRITICAL, HIGH, MEDIUM
- **When:** Before building Docker image

#### SAST (Static Application Security Testing)
- **Tool:** Semgrep
- **What it scans:** Source code for security issues
- **Rules:**
  - `p/security-audit` - General security issues
  - `p/secrets` - Hardcoded secrets
  - `p/owasp-top-ten` - OWASP Top 10 vulnerabilities
- **Languages:** Node.js, Python, Java, Go, PHP
- **When:** Before building Docker image

---

### 2. **Build Security** (Docker Image)

#### Container Image Scanning
- **Tool:** Trivy (image scan)
- **What it scans:** 
  - OS vulnerabilities (Ubuntu, Alpine, etc.)
  - Library vulnerabilities
  - Misconfigurations
- **Severity:** CRITICAL, HIGH, MEDIUM
- **When:** After Docker build, before push

#### Security Gate
- **Action:** **FAIL BUILD** if CRITICAL vulnerabilities found
- **Exceptions:** Unfixed vulnerabilities ignored
- **Purpose:** Prevent vulnerable images from reaching production

#### SBOM Generation
- **Tool:** Trivy
- **Format:** CycloneDX JSON
- **What it contains:** Complete software bill of materials
- **Retention:** 90 days
- **Purpose:** Supply chain security, compliance

---

### 3. **Post-Build Security**

#### Image Tagging
```
cart:abc123def           # Original
cart:tested-abc123def    # After security scans pass
```

---

## Multi-Language Support

### Service Languages

| Service | Language | Package Manager | Security Tools |
|---------|----------|----------------|----------------|
| **web** | Node.js | npm | Trivy, Semgrep |
| **cart** | Node.js | npm | Trivy, Semgrep |
| **catalogue** | Node.js | npm | Trivy, Semgrep |
| **user** | Node.js | npm | Trivy, Semgrep |
| **payment** | Python | pip | Trivy, Semgrep |
| **shipping** | Java | Maven | Trivy, Semgrep |
| **ratings** | PHP | Composer | Trivy, Semgrep |
| **dispatch** | Go | go.mod | Trivy, Semgrep |
| **mysql** | SQL | - | Trivy |
| **mongo** | JavaScript | - | Trivy |

---

## Security Reports

### GitHub Security Tab

All security findings are uploaded to GitHub Security tab:

1. **Code Scanning Alerts**
   - SAST findings (Semgrep)
   - Dependency vulnerabilities
   - Container vulnerabilities

2. **Categories:**
   - `dependencies-{service}` - Dependency scan results
   - `sast-{service}` - Code security issues
   - `container-{service}` - Image vulnerabilities

3. **Viewing Results:**
   ```
   GitHub → Security → Code scanning alerts
   ```

### SBOM Artifacts

Software Bill of Materials available as artifacts:
```
GitHub → Actions → Run → Artifacts → sbom-{service}
```

---

## Security Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CODE PUSH (Developer)                    │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              STAGE 1: Pre-Build Security                    │
│  ✓ Secret Detection (TruffleHog)                           │
│  ✓ Dependency Scan (Trivy FS)                              │
│  ✓ SAST Code Scan (Semgrep)                                │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              STAGE 2: Docker Build                          │
│  • Build image with commit SHA                              │
│  • Push to ACR                                              │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              STAGE 3: Image Security                        │
│  ✓ Container Scan (Trivy Image)                            │
│  ✓ SBOM Generation (CycloneDX)                             │
│  ⚠️  Security Gate (Fail on CRITICAL)                       │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              STAGE 4: Tag & Deploy                          │
│  • Tag as tested-{sha}                                      │
│  • Deploy to environment                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Security Best Practices Implemented

### ✅ Shift-Left Security
- Security checks **before** build (not after)
- Catch issues early in development

### ✅ Defense in Depth
- Multiple security tools at different stages
- No single point of failure

### ✅ Fail Fast
- Security gate stops vulnerable images
- Prevents deployment of critical vulnerabilities

### ✅ Continuous Monitoring
- Scans on every push
- Weekly scheduled scans

### ✅ Transparency
- All findings in GitHub Security tab
- SBOM for supply chain visibility

### ✅ Multi-Language Support
- Works for Node.js, Python, Java, Go, PHP
- Automatic detection per service

---

## Configuration

### Security Gate Severity

Current: **CRITICAL** vulnerabilities fail the build

To change:
```yaml
# build-and-push.yml
severity: 'CRITICAL,HIGH'  # Fail on HIGH too
```

### Ignore Unfixed Vulnerabilities

Current: **Enabled** (ignore vulnerabilities with no fix)

To change:
```yaml
ignore-unfixed: false  # Fail even if no fix available
```

### SBOM Retention

Current: **90 days**

To change:
```yaml
retention-days: 365  # Keep for 1 year
```

---

## Compliance

This DevSecOps pipeline helps meet:

- ✅ **OWASP Top 10** - SAST rules cover common vulnerabilities
- ✅ **CIS Benchmarks** - Container security scanning
- ✅ **NIST SSDF** - Secure software development framework
- ✅ **SOC 2** - Security controls and audit trail
- ✅ **SBOM Requirements** - Executive Order 14028 compliance

---

## Viewing Security Results

### 1. GitHub Security Tab
```
Repository → Security → Code scanning alerts
```

### 2. Pull Request Checks
Security scans run on PRs and show results inline

### 3. Action Logs
```
Actions → Latest run → security-scan job
```

### 4. SBOM Download
```
Actions → Latest run → Artifacts → sbom-{service}.json
```

---

## Troubleshooting

### Build Fails on Security Gate

**Symptom:** Build fails with "Security Gate Check" error

**Solution:**
1. Check GitHub Security tab for vulnerabilities
2. Update dependencies to patched versions
3. If no fix available, add exception (with justification)

### False Positives

**Symptom:** Security tool reports issue that's not real

**Solution:**
1. Verify it's actually a false positive
2. Add to ignore list in tool configuration
3. Document why it's ignored

---

## Future Enhancements

### Planned:
- [ ] License compliance scanning (FOSSA)
- [ ] Runtime security (Falco)
- [ ] Policy as Code (OPA)
- [ ] Security metrics dashboard

---

## References

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Semgrep Rules](https://semgrep.dev/explore)
- [TruffleHog](https://github.com/trufflesecurity/trufflehog)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CycloneDX SBOM](https://cyclonedx.org/)
