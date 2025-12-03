# Files to Delete and Why

## Duplicate/Obsolete Values Files

### ❌ DELETE: `helm/azure-values.yaml`
**Why**: Superseded by `helm/values-final.yaml`
- Incomplete resource definitions
- Missing optimized CPU/memory settings
- Created during initial setup, not production-ready

### ❌ DELETE: `helm/values-optimized.yaml`
**Why**: Intermediate version, superseded by `helm/values-final.yaml`
- Created during troubleshooting
- Had incorrect resource limits (caused MySQL deployment failure)
- `values-final.yaml` is the corrected version

### ❌ DELETE: `helm/hpa-values.yaml`
**Why**: Incomplete HPA configuration
- Only contains HPA settings without base configuration
- Not integrated with main values file
- HPA can be added to `values-final.yaml` when needed

### ✅ KEEP: `helm/values-final.yaml`
**Why**: Production-ready, tested, working configuration
- Optimized resources for 2-node cluster
- All 12 pods running successfully
- Includes Azure-specific settings (managed-csi storage)

### ✅ KEEP: `helm/values-azure.yaml`
**Why**: Base reference for Azure-specific settings
- Documents Azure vs AWS differences
- Useful for understanding platform-specific configs
- Can serve as template for other environments

## Duplicate/Obsolete Scripts

### ❌ DELETE: `deploy-with-autoscaling.sh`
**Why**: Superseded by `deploy-robot-shop.sh`
- Incomplete implementation (hangs with --wait flag)
- Missing error handling
- No interactive prompts
- `deploy-robot-shop.sh` is more robust

### ❌ DELETE: `quick-start.sh`
**Why**: Outdated, doesn't use fixed templates
- Created before Helm template fixes
- Uses old values files
- Doesn't include resource optimization
- `deploy-robot-shop.sh` is the current standard

### ✅ KEEP: `deploy-robot-shop.sh`
**Why**: Production-ready automated deployment
- Uses `values-final.yaml`
- Interactive upgrade prompts
- Comprehensive status checks
- Error handling

## Backup Files (If Any)

### ❌ DELETE: `helm/templates/*.bak`
**Why**: Backup files from template fixes
- Original templates had hardcoded resources
- Fixed versions are now in place
- Git history preserves original versions

## Summary

### Files to Delete:
```bash
rm helm/azure-values.yaml
rm helm/values-optimized.yaml
rm helm/hpa-values.yaml
rm deploy-with-autoscaling.sh
rm quick-start.sh
rm helm/templates/*.bak  # If any exist
```

### Files to Keep:
```
✅ helm/values-final.yaml          # Production values
✅ helm/values-azure.yaml          # Reference/documentation
✅ deploy-robot-shop.sh            # Deployment script
✅ HELM-FIXES-APPLIED.md           # Documentation
✅ helm/templates/*                # Fixed templates
```

## Cleanup Command

Run this to clean up obsolete files:

```bash
cd /path/to/robot-shop-azure-platform

# Remove obsolete values files
rm -f helm/azure-values.yaml
rm -f helm/values-optimized.yaml
rm -f helm/hpa-values.yaml

# Remove obsolete scripts
rm -f deploy-with-autoscaling.sh
rm -f quick-start.sh

# Remove any backup files
rm -f helm/templates/*.bak

echo "✅ Cleanup complete!"
```

## Rationale

**Keep it simple**: One production values file, one deployment script, one set of templates.

**Why not keep everything?**
- Confusing for future users/maintainers
- Multiple values files → which one to use?
- Multiple scripts → which one works?
- Backup files → unnecessary with Git

**Git preserves history**: All original versions are in Git history if needed for reference.
