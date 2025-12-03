# CI/CD Pipeline Architecture

```mermaid
graph TB
    subgraph "Developer Workflow"
        DEV[Developer] -->|1. Code Change| FEATURE[Feature Branch]
        FEATURE -->|2. Create PR| PR[Pull Request]
    end

    subgraph "CI Pipeline - Quality Gates"
        PR -->|Trigger| CI[CI Workflow]
        CI --> LINT[Lint & Validate]
        CI --> TEST[Unit Tests]
        CI --> SCAN[Security Scan]
        SCAN -->|Pass| MERGE[Merge to develop]
        SCAN -->|Fail| BLOCK[Block Merge]
    end

    subgraph "Build Once"
        MERGE -->|Trigger| BUILD[Build & Push]
        BUILD --> DETECT[Detect Changes]
        DETECT --> DOCKER[Build Docker Image]
        DOCKER --> TAG[Tag: commit-sha]
        TAG --> ACR[Push to ACR]
        ACR --> TRIVY[Trivy Scan]
        TRIVY --> TESTED[Tag: tested-sha]
    end

    subgraph "Deploy Many - Dev"
        TESTED -->|Auto Deploy| DEV_DEPLOY[Deploy to Dev]
        DEV_DEPLOY --> DEV_VERIFY[Verify Deployment]
        DEV_VERIFY --> DEV_SMOKE[Smoke Test]
    end

    subgraph "Deploy Many - Staging"
        DEV_SMOKE -->|Create Release| RELEASE[Release Branch]
        RELEASE -->|Auto Deploy| STG_DEPLOY[Deploy to Staging]
        STG_DEPLOY --> STG_VERIFY[Verify Deployment]
        STG_VERIFY --> STG_TEST[Integration Tests]
    end

    subgraph "Deploy Many - Production"
        STG_TEST -->|Merge to Main| MAIN[Main Branch]
        MAIN -->|Manual Approval| APPROVE[Approval Gate]
        APPROVE -->|Deploy| PROD_DEPLOY[Deploy to Production]
        PROD_DEPLOY --> PROD_VERIFY[Verify Deployment]
        PROD_VERIFY --> PROD_SMOKE[Production Tests]
    end

    style BUILD fill:#ff9900
    style TRIVY fill:#e74c3c
    style APPROVE fill:#f39c12
    style PROD_DEPLOY fill:#27ae60
```

## Key Points

- **Build Once**: Single Docker image built and tagged with commit SHA
- **Deploy Many**: Same image deployed to dev, staging, and production
- **Security**: Trivy scanning integrated in build pipeline
- **Quality Gates**: CI validates before merge
- **Approval**: Manual approval required for production
