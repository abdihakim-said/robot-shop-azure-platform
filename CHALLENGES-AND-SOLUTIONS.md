# Challenges and Solutions - Robot Shop Azure Platform

This document chronicles all the challenges encountered during the implementation of this enterprise microservices platform and the solutions applied. Each challenge includes the problem, investigation process, root cause analysis, and the final solution.

---

## Table of Contents
1. [Shipping Service Restart Loop](#1-shipping-service-restart-loop)
2. [Cart Service CRITICAL Vulnerabilities (CVE-2025-7783)](#2-cart-service-critical-vulnerabilities)
3. [TruffleHog Secret Scanning Failures](#3-trufflehog-secret-scanning-failures)
4. [Semgrep SARIF Upload Issues](#4-semgrep-sarif-upload-issues)
5. [CI/CD Pipeline Architecture Decisions](#5-cicd-pipeline-architecture-decisions)

---

## 1. Shipping Service Restart Loop

### Problem
```
NAME                        READY   STATUS    RESTARTS   AGE
shipping-7d8f8d8f8d-xxxxx   1/1     Running   99         10m
```
Shipping service was in a continuous restart loop with 99 restarts.

### Investigation Process
```bash
# Step 1: Check pod logs
kubectl logs shipping-7d8f8d8f8d-xxxxx

# Output showed:
# Error: Public Key Retrieval is not allowed
# Connection to MySQL failed
```

```bash
# Step 2: Exec into MySQL pod to verify user
kubectl exec -it mysql-xxxxx -- mysql -u root -p

mysql> SELECT User, Host FROM mysql.user;
# Result: shipping user was missing!
```

### Root Cause
1. MySQL deployment was using vanilla MySQL image instead of custom image
2. Custom MySQL image had initialization script to create shipping user
3. Vanilla image had no shipping user
4. Shipping service couldn't authenticate to MySQL
5. Even if user existed, JDBC connection needed `allowPublicKeyRetrieval=true` parameter

### Solution
**File**: `shipping/src/main/java/com/instana/robotshop/shipping/JpaConfig.java`

```java
// Before:
jdbc:mysql://mysql:3306/cities?useSSL=false

// After:
jdbc:mysql://mysql:3306/cities?useSSL=false&allowPublicKeyRetrieval=true
```

**Also updated**: `shipping/src/main/resources/application.properties`

### Lessons Learned
- Always verify database users exist before deploying dependent services
- JDBC connection strings need proper security parameters
- MySQL 8.0+ requires explicit public key retrieval permission
- Check container image tags - ensure custom images are being used
- Pod restart counts are a key indicator of configuration issues

---

## 2. Cart Service CRITICAL Vulnerabilities

### Problem
Security gate blocking cart service deployment with 16 CRITICAL vulnerabilities:
```
Total: 16 (CRITICAL: 16)
- CVE-2024-32002 (git RCE)
- CVE-2021-3177 (Python buffer overflow)
- CVE-2022-48565 (Python XXE)
- CVE-2025-7783 (form-data unsafe random)
```

### Investigation Journey

#### Attempt 1: Update Base Image ❌
```dockerfile
# Changed from:
FROM node:14

# To:
FROM node:14-bullseye-slim
```
**Result**: Reduced from 16 to 6 CRITICAL (fixed Debian 10 → 11 issues)

#### Attempt 2: Add form-data to package.json ❌
```json
"dependencies": {
  "form-data": "4.0.4"
}
```
**Result**: Still showing form-data 2.3.3 in scans

#### Attempt 3: Use npm overrides ❌
```json
"overrides": {
  "form-data": "4.0.4"
}
```
**Result**: Failed - overrides is npm 8.3+ feature, Node 14 has npm 6.x

#### Attempt 4: Replace request package with axios ❌
```javascript
// Replaced deprecated request with axios
const axios = require('axios');
```
**Result**: Still showing form-data 2.3.3!

#### Attempt 5: Deep Analysis - Found Root Cause! ✅

**Investigation**:
```bash
# Checked what Trivy was actually scanning
gh run view --log | grep "form-data (package.json)"

# Output showed:
# usr/local/lib/node_modules/npm/node_modules/form-data
```

**Revelation**: Trivy was scanning the **global npm installation**, not our app dependencies!

### Root Cause
- Node.js 14 ships with npm 6.x
- npm 6.x has form-data@2.3.3 as a dependency
- Trivy scans entire container image including `/usr/local/lib/node_modules/npm`
- Our app dependencies were clean, but npm CLI tool itself had the vulnerability

### Solution
```dockerfile
FROM node:14-bullseye-slim

# Update npm to 8.x (compatible with Node 14, has patched dependencies)
RUN npm install -g npm@8

COPY package.json /opt/server/
RUN npm install
```

**Result**: ✅ 0 CRITICAL vulnerabilities

### Why Not Node 20?
Initially considered but chose npm upgrade instead:
- Node 14 code was already working
- Minimal change principle
- npm 8 compatible with Node 14
- Could upgrade to Node 20 later as optimization

### Lessons Learned
- Security scanners check **entire container**, not just app code
- Build tools (npm, pip, etc.) can have vulnerabilities
- Always investigate what the scanner is actually finding
- Don't assume vulnerabilities are in your application code
- Deep analysis beats trial-and-error
- npm version matters for security, not just features

---

## 3. TruffleHog Secret Scanning Failures

### Problem
TruffleHog consistently failing with different exit codes:
- Exit code 128: "dubious ownership in repository"
- Exit code 127: "command not found"

### Investigation Journey

#### Attempt 1: Fix Git Ownership ❌
```yaml
container:
  image: semgrep/semgrep

steps:
  - name: Fix git ownership
    run: git config --global --add safe.directory /__w/robot-shop-azure-platform/robot-shop-azure-platform
```
**Result**: Exit code changed from 128 to 127

#### Attempt 2: Root Cause Analysis ✅

**Investigation**:
```bash
# Checked TruffleHog logs
gh run view --log | grep "TruffleHog"

# Exit code 127 = command not found
# TruffleHog action needs git
# semgrep/semgrep container is minimal (no git installed)
```

### Root Cause
- Running security-scan job in `semgrep/semgrep` container
- Container is minimal Python environment for Semgrep only
- Doesn't include git, which TruffleHog action requires
- Git ownership fix worked, but git binary wasn't available

### Solution
Remove container, run on host runner:

```yaml
# Before:
security-scan:
  runs-on: ubuntu-latest
  container:
    image: semgrep/semgrep
  steps:
    - name: Secret Detection (TruffleHog)
      uses: trufflesecurity/trufflehog@main

# After:
security-scan:
  runs-on: ubuntu-latest  # No container
  steps:
    - name: Secret Detection (TruffleHog)
      uses: trufflesecurity/trufflehog@main  # Has git on host
    
    - name: Code Security Scan (Semgrep)
      run: |
        docker run --rm -v "$PWD:/src" semgrep/semgrep semgrep scan --config auto
```

**Result**: ✅ TruffleHog working, 0 secrets found

### Lessons Learned
- GitHub Actions containers are minimal - don't assume tools are available
- Exit code 127 always means "command not found"
- Exit code 128 is git-specific (usually ownership/permission issues)
- Ubuntu runners have git, docker, and most tools pre-installed
- Running on host is simpler than managing container dependencies
- Use containers for specific tools (Semgrep), not entire jobs

---

## 4. Semgrep SARIF Upload Issues

### Problem
Semgrep scanning successfully but SARIF file not uploading to GitHub Security:
```
Error: Path does not exist: semgrep.sarif
```

### Investigation Journey

#### Attempt 1: Using Deprecated Action ❌
```yaml
- name: Code Security Scan (Semgrep)
  uses: returntocorp/semgrep-action@v1
  with:
    scanPath: ./${{ matrix.service }}
    generateSarif: true
```
**Result**: 
- Action parameters invalid
- Action deprecated (archived April 2024)

#### Attempt 2: Docker with Wrong Path ❌
```yaml
- name: Code Security Scan (Semgrep)
  run: |
    cd ${{ matrix.service }}
    docker run --rm -v "${PWD}:/src" returntocorp/semgrep \
      semgrep scan --config=auto --sarif --output=../semgrep-cart.sarif
```
**Result**: 
- Semgrep ran successfully (found 2 findings)
- SARIF saved to wrong location (../semgrep-cart.sarif from inside cart dir)
- Upload step couldn't find file

#### Attempt 3: Container with Correct Path ✅
```yaml
container:
  image: semgrep/semgrep

steps:
  - name: Code Security Scan (Semgrep)
    run: semgrep scan --config auto --sarif --output=semgrep-${{ matrix.service }}.sarif
```
**Result**: ✅ SARIF generated and uploaded successfully

#### Final Solution: Host Runner with Docker ✅
```yaml
# No container
steps:
  - name: Code Security Scan (Semgrep)
    run: |
      docker run --rm -v "$PWD:/src" semgrep/semgrep \
        semgrep scan --config auto --sarif --output=/src/semgrep-${{ matrix.service }}.sarif
```
**Result**: ✅ SARIF in correct location, uploaded successfully

### Root Cause
- Path confusion between host and container
- `cd` into service directory changed working directory
- `../` relative path didn't resolve where expected
- Upload step looked in wrong directory

### Lessons Learned
- Always use absolute paths or $PWD for Docker volume mounts
- Test file paths with `ls` commands in pipeline
- SARIF files must be in GitHub Actions working directory
- Official Semgrep documentation recommends direct command, not action
- returntocorp/semgrep-action is deprecated - use semgrep/semgrep container

---

## 5. CI/CD Pipeline Architecture Decisions

### Challenge: Monorepo with 12 Microservices

**Question**: How to structure CI/CD for multiple services in one repository?

### Options Considered

#### Option A: Single Monolithic Pipeline ❌
```yaml
# One workflow, builds all services every time
jobs:
  build-all:
    steps:
      - build cart
      - build web
      - build catalogue
      # ... all 12 services
```
**Pros**: Simple
**Cons**: Slow, wastes resources, no service independence

#### Option B: Separate Repositories (Polyrepo) ❌
**Pros**: Complete service independence
**Cons**: 
- 12 repositories to manage
- Shared code duplication
- Complex cross-service changes
- Not suitable for this project structure

#### Option C: Monorepo with Smart Detection ✅ (Chosen)
```yaml
# Detect changed services
detect-changes:
  outputs:
    services: ${{ steps.changes.outputs.services }}

# Build only changed services (parallel)
build-and-push:
  strategy:
    matrix:
      service: ${{ fromJson(needs.detect-changes.outputs.services) }}

# Deploy each service independently
deploy-cart:
  needs: build-and-push
  if: contains(needs.detect-changes.outputs.services, 'cart')
```

### Architecture Decisions

#### 1. Single Build Pipeline with Matrix Strategy
**Decision**: One `build-and-push.yml` with matrix for all services

**Why**:
- Industry best practice (Google, Uber, Airbnb use this)
- Parallel execution (all changed services build simultaneously)
- Single source of truth for build process
- Easy to maintain and update
- Consistent security scanning across all services

#### 2. Separate Deployment Workflows Per Service
**Decision**: Individual `service-{name}.yml` for each service

**Why**:
- Microservices independence
- Team autonomy (different teams can own different services)
- Flexible deployment timing
- Can deploy one service without affecting others
- Manual deployment option via workflow_dispatch

#### 3. workflow_call Pattern
**Decision**: Use `workflow_call` trigger instead of only `workflow_dispatch`

```yaml
on:
  workflow_call:  # Can be called from other workflows
    inputs:
      image-tag:
        required: true
  workflow_dispatch:  # Can be triggered manually
    inputs:
      image-tag:
        required: true
```

**Why**:
- Works from any branch (develop, release/*, main)
- No need to merge to main for every test
- Enables automated deployment from build pipeline
- Still allows manual deployments
- Supports GitFlow branching strategy

#### 4. Build Once, Deploy Many
**Decision**: Tag images with commit SHA, promote same artifact

```yaml
tags: |
  ${{ env.ACR_LOGIN_SERVER }}/${{ matrix.service }}:${{ github.sha }}
  ${{ env.ACR_LOGIN_SERVER }}/${{ matrix.service }}:latest
```

**Why**:
- Same artifact across dev/staging/prod
- No rebuild differences
- Faster deployments
- Guaranteed consistency
- Industry standard practice

#### 5. DevSecOps Security Scanning
**Decision**: 3-layer security scanning before build

```yaml
security-scan:
  steps:
    - TruffleHog (secrets)
    - Trivy (dependencies)
    - Semgrep (SAST)

build-and-push:
  needs: security-scan  # Must pass security first
```

**Why**:
- Shift-left security
- Catch issues before deployment
- Security gate blocks CRITICAL vulnerabilities
- SARIF uploads to GitHub Security Dashboard
- Compliance and audit trail

### Lessons Learned
- Monorepo with smart detection beats polyrepo for this use case
- Matrix strategy enables parallel builds without complexity
- Separate deployment workflows provide microservices independence
- workflow_call is more flexible than workflow_dispatch alone
- Security scanning should be a gate, not just informational
- Build once, deploy many is non-negotiable for consistency

---

## Summary of Key Takeaways

### Debugging Principles
1. **Check logs first** - `kubectl logs` is your best friend
2. **Verify assumptions** - Don't assume images, users, or configs are correct
3. **Deep analysis beats trial-and-error** - Understand what tools are actually scanning
4. **Exit codes tell a story** - 127 = not found, 128 = git issue, 1 = general error
5. **Read the actual error** - Don't just see "failed", read what failed

### Security Best Practices
1. **Scan entire container** - Not just your app code
2. **Update build tools** - npm, pip, etc. can have vulnerabilities
3. **Use security gates** - Block deployments on CRITICAL issues
4. **Multiple scan types** - Secrets, dependencies, and code analysis
5. **SARIF integration** - Centralize findings in GitHub Security

### CI/CD Architecture
1. **Detect changes** - Only build what changed
2. **Matrix strategy** - Parallel execution for speed
3. **Separate concerns** - Build once, deploy independently
4. **workflow_call pattern** - Flexibility across branches
5. **Commit SHA tagging** - Immutable artifact promotion

### Container Best Practices
1. **Minimal images** - Use -slim or -alpine variants
2. **Update base images** - Security patches matter
3. **Know what's installed** - Don't assume tools are available
4. **Host vs container** - Choose based on tool requirements
5. **Volume mounts** - Use $PWD for clarity

### Problem-Solving Approach
1. **Reproduce** - Verify the issue exists
2. **Investigate** - Gather logs and evidence
3. **Hypothesize** - Form theories about root cause
4. **Test** - Try solutions incrementally
5. **Verify** - Confirm the fix works
6. **Document** - Record for future reference

---

## Metrics

### Before Fixes
- ❌ Shipping service: 99 restarts
- ❌ Cart service: 16 CRITICAL vulnerabilities
- ❌ TruffleHog: Exit code 128/127
- ❌ Semgrep: SARIF upload failing
- ❌ Security gate: Blocking deployments

### After Fixes
- ✅ All 12 services: Running stable
- ✅ Cart service: 0 CRITICAL vulnerabilities
- ✅ TruffleHog: 0 secrets found
- ✅ Semgrep: SARIF uploaded successfully
- ✅ Security gate: Passing
- ✅ Full CI/CD pipeline: Operational

### Time Investment
- Shipping service fix: ~30 minutes
- Cart CVE resolution: ~3 hours (multiple attempts)
- TruffleHog fix: ~1 hour
- Semgrep SARIF fix: ~45 minutes
- Pipeline architecture: ~2 hours

**Total**: ~7 hours of debugging and optimization

**Value**: Production-ready DevSecOps pipeline with enterprise security standards

---

## Interview Talking Points

When discussing these challenges in interviews:

1. **Demonstrate problem-solving**: Walk through your investigation process
2. **Show technical depth**: Explain root causes, not just symptoms
3. **Highlight learning**: What would you do differently next time?
4. **Emphasize impact**: How did your fix improve the system?
5. **Connect to best practices**: Reference industry standards

### Example Answer Structure
```
"We encountered a challenge where [problem]. 

I investigated by [steps taken], which revealed [root cause]. 

The key insight was [aha moment]. 

I implemented [solution], which resulted in [outcome]. 

This taught me [lesson learned], and I would apply this by [future application]."
```

---

**Document Version**: 1.0  
**Last Updated**: December 4, 2024  
**Author**: Platform Engineering Team  
**Status**: Production-Ready ✅
