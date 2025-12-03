# GitFlow Branching Strategy

```mermaid
gitGraph
    commit id: "Initial"
    branch develop
    checkout develop
    commit id: "Setup"
    
    branch feature/web-ui
    checkout feature/web-ui
    commit id: "Add UI"
    commit id: "Fix bugs"
    
    checkout develop
    merge feature/web-ui tag: "CI ✓"
    commit id: "Deploy to Dev" type: HIGHLIGHT
    
    branch feature/cart-opt
    checkout feature/cart-opt
    commit id: "Optimize cart"
    
    checkout develop
    merge feature/cart-opt
    commit id: "Deploy to Dev" type: HIGHLIGHT
    
    branch release/v1.0.0
    checkout release/v1.0.0
    commit id: "Bump version"
    commit id: "Deploy to Staging" type: HIGHLIGHT
    commit id: "Fix staging bug"
    
    checkout main
    merge release/v1.0.0 tag: "v1.0.0"
    commit id: "Deploy to Prod" type: REVERSE
    
    checkout develop
    merge main
    
    checkout main
    branch hotfix/critical
    checkout hotfix/critical
    commit id: "Fix critical bug"
    
    checkout main
    merge hotfix/critical tag: "v1.0.1"
    
    checkout develop
    merge main
```

## Branch Strategy

### Permanent Branches
- **main**: Production releases
- **develop**: Integration branch

### Temporary Branches
- **feature/***: Feature development
- **release/***: Release preparation
- **hotfix/***: Production fixes

## Environment Mapping

| Branch | Environment | Deployment |
|--------|-------------|------------|
| develop | Development | Automatic |
| release/* | Staging | Automatic |
| main | Production | Manual Approval |

## Workflow

1. **Feature Development**: feature/* → develop
2. **Release Preparation**: develop → release/*
3. **Production**: release/* → main
4. **Hotfix**: main → hotfix/* → main
