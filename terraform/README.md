# 🏗️ Terraform Infrastructure

This directory contains the modular Terraform infrastructure for Robot Shop on Azure.

## 📁 Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── aks/                   # AKS cluster module
│   ├── networking/            # VNet, NSG module
│   ├── monitoring/            # Azure Monitor module
│   └── storage/               # ACR, Storage module
│
├── environments/              # Environment-specific configurations
│   ├── dev/                  # Development environment
│   └── prod/                 # Production environment
│
└── helm-values/              # Helm chart value templates
    └── prometheus-values.yaml
```

## 🚀 Quick Start

### Deploy Development Environment

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Deploy Production Environment

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## 📚 Documentation

- **[Modules & Environments Guide](../MODULES-AND-ENVIRONMENTS.md)** - Complete architecture documentation
- **[Architecture Comparison](../ARCHITECTURE-COMPARISON.md)** - Before/after comparison
- **[Deployment Guide](../docs/deployment-guide.md)** - Step-by-step deployment

## 🎯 Module Overview

### AKS Module
Manages AKS cluster, Log Analytics, and Container Insights.

### Networking Module
Manages VNet, subnets, and Network Security Groups.

### Monitoring Module
Manages Application Insights, Action Groups, and diagnostic settings.

### Storage Module
Manages Azure Container Registry and Storage Accounts.

## 🌍 Environments

### Development
- Cost-optimized configuration
- 2 nodes (1-3 autoscale)
- Basic ACR, LRS storage
- ~$60-80/month

### Production
- High-availability configuration
- 5 nodes (3-10 autoscale)
- Premium ACR, GRS storage
- ~$300-400/month

## ✅ Best Practices

- ✅ Modular, reusable components
- ✅ Environment separation
- ✅ Remote state support
- ✅ Consistent tagging
- ✅ Security best practices
- ✅ Cost optimization

---

**Start with the dev environment, then deploy prod when ready!**
# CI/CD Test - Wed  3 Dec 2025 05:15:31 GMT
# CI/CD Test - Wed  3 Dec 2025 05:24:20 GMT
# DevSecOps Infrastructure Pipeline
