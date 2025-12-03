# Robot Shop - Enterprise Microservices Platform on Azure AKS

[![Azure](https://img.shields.io/badge/Azure-AKS-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/en-us/services/kubernetes-service/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Helm](https://img.shields.io/badge/Helm-Charts-0F1689?logo=helm)](https://helm.sh/)

> Production-grade microservices platform demonstrating enterprise DevOps, GitOps, and cloud-native best practices on Azure.

## 🎯 Project Overview

A complete end-to-end implementation of a 12-service microservices application on Azure Kubernetes Service (AKS), showcasing:

- **Enterprise CI/CD**: Build once, deploy many with GitFlow branching
- **DevSecOps**: Integrated security scanning and compliance
- **Infrastructure as Code**: Modular Terraform with 3-tier environments
- **Microservices Architecture**: Independent service deployments
- **Production-Ready**: Autoscaling, monitoring, and high availability

**Live Demo**: http://57.151.39.73:8080 (Development environment)

---

## 📊 Architecture

### Infrastructure Architecture
![Infrastructure](docs/diagrams/infrastructure.md)

### CI/CD Pipeline
![CI/CD](docs/diagrams/cicd-pipeline.md)

### Microservices
![Microservices](docs/diagrams/microservices.md)

[View All Diagrams →](docs/diagrams/)

---

## 🚀 Key Features

### Enterprise CI/CD Pipeline
- ✅ **Build Once, Deploy Many** - Single artifact across all environments
- ✅ **Per-Service Pipelines** - Independent microservice deployments
- ✅ **GitFlow Branching** - feature → develop → release → main
- ✅ **DevSecOps** - Trivy security scanning, SARIF reports
- ✅ **Environment Promotion** - Automated dev → staging, manual prod approval

### Infrastructure
- ✅ **Modular Terraform** - 4 reusable modules (AKS, networking, monitoring, storage)
- ✅ **3-Tier Environments** - Dev, staging, production configurations
- ✅ **Autoscaling** - HPA (pod-level) + Cluster Autoscaler (node-level)
- ✅ **High Availability** - Multi-node, multi-replica, health checks

### Microservices
- ✅ **12 Services** - 8 stateless, 4 stateful
- ✅ **Polyglot** - Node.js, Python, Java, Go, PHP
- ✅ **Independent Deployment** - Per-service CI/CD pipelines
- ✅ **Service Mesh Ready** - Prepared for Istio/Linkerd

### Monitoring & Observability
- ✅ **Prometheus + Grafana** - Metrics and dashboards
- ✅ **Azure Log Analytics** - Centralized logging
- ✅ **Application Insights** - APM and tracing
- ✅ **Metrics Server** - HPA metrics

---

## 🏗️ Technology Stack

| Layer | Technology |
|-------|------------|
| **Cloud** | Azure (AKS, VNet, ACR, Log Analytics) |
| **Orchestration** | Kubernetes 1.31, Helm 3 |
| **IaC** | Terraform 1.6 |
| **CI/CD** | GitHub Actions |
| **Monitoring** | Prometheus, Grafana, Azure Monitor |
| **Security** | Trivy, Azure RBAC, Network Policies |
| **Languages** | Node.js, Python, Java, Go, PHP |

---

## 📁 Project Structure

```
.
├── .github/workflows/          # CI/CD pipelines
│   ├── build-and-push.yml     # Build once pipeline
│   ├── service-*.yml          # Per-service deployments
│   └── infrastructure.yml     # Terraform automation
├── terraform/
│   ├── modules/               # Reusable modules
│   │   ├── aks/              # AKS cluster
│   │   ├── networking/       # VNet, NSG
│   │   ├── monitoring/       # Observability
│   │   └── storage/          # ACR, Storage
│   └── environments/          # Environment configs
│       ├── dev/
│       ├── staging/
│       └── prod/
├── helm/
│   ├── templates/             # Kubernetes manifests
│   ├── values.yaml           # Default values
│   ├── values-dev.yaml       # Dev environment
│   ├── values-staging.yaml   # Staging environment
│   └── values-prod.yaml      # Production environment
├── docs/
│   └── diagrams/             # Architecture diagrams
└── [service-directories]/     # 12 microservices
```

---

## 🚦 Quick Start

### Prerequisites
- Azure CLI
- kubectl
- Terraform 1.6+
- Helm 3+

### 1. Deploy Infrastructure

```bash
# Login to Azure
az login

# Deploy dev environment
cd terraform/environments/dev
terraform init
terraform apply

# Get AKS credentials
az aks get-credentials \
  --resource-group robot-shop-dev-rg \
  --name robot-shop-dev-aks
```

### 2. Deploy Application

```bash
# Deploy with Helm
helm install robot-shop ./helm \
  --namespace robot-shop \
  --create-namespace \
  --values ./helm/values-dev.yaml

# Or use deployment script
./deploy-robot-shop.sh dev
```

### 3. Verify Deployment

```bash
# Check pods
kubectl get pods -n robot-shop

# Check services
kubectl get svc -n robot-shop

# Get web URL
kubectl get svc web -n robot-shop
```

---

## 🔄 CI/CD Workflow

### GitFlow Branching

```
feature/* → develop → release/* → main
  (local)    (dev)     (staging)   (prod)
```

### Deployment Flow

```bash
# 1. Feature development
git checkout -b feature/cart-optimization
# Make changes
git push origin feature/cart-optimization
# Create PR → CI runs

# 2. Deploy to dev
git checkout develop
git merge feature/cart-optimization
git push origin develop
# → Auto-deploys to dev

# 3. Deploy to staging
git checkout -b release/v1.0.0
git push origin release/v1.0.0
# → Auto-deploys to staging

# 4. Deploy to production
git checkout main
git merge release/v1.0.0
git push origin main
# → Manual approval → deploys to prod
```

[View Complete CI/CD Documentation →](GITFLOW-AND-CICD.md)

---

## 🎯 Environment Strategy

| Environment | Branch | Nodes | HPA | Deployment | Purpose |
|-------------|--------|-------|-----|------------|---------|
| **Development** | develop | 2-5 | ❌ | Automatic | Fast iteration |
| **Staging** | release/* | 2-5 | ✅ | Automatic | Pre-prod testing |
| **Production** | main | 3-10 | ✅ | Manual approval | Live traffic |

### Resource Configuration

| Service | Dev CPU | Staging CPU | Prod CPU |
|---------|---------|-------------|----------|
| Web | 30m | 40m | 50m |
| Cart | 30m | 40m | 50m |
| MySQL | 50m | 75m | 100m |

[View Environment Details →](ENVIRONMENTS.md)

---

## 📈 Autoscaling

### Two-Layer Autoscaling

**Horizontal Pod Autoscaler (HPA)**
- Scales pods based on CPU (70% target)
- Staging: 1-3 replicas
- Production: 2-10 replicas

**Cluster Autoscaler**
- Scales nodes based on pending pods
- Dev: 2-5 nodes
- Production: 3-10 nodes

[View Autoscaling Architecture →](docs/diagrams/autoscaling.md)

---

## 🔒 Security & DevSecOps

### Security Features
- ✅ **Trivy Scanning** - Container vulnerability scanning
- ✅ **SARIF Reports** - GitHub Security integration
- ✅ **Azure RBAC** - Role-based access control
- ✅ **Network Policies** - Pod-to-pod security
- ✅ **Secrets Management** - Azure Key Vault ready

### Security Scanning
```yaml
# Integrated in CI/CD
- Dockerfile linting (Hadolint)
- Image scanning (Trivy)
- Dependency scanning
- SARIF report generation
```

[View DevSecOps Documentation →](BUILD-ONCE-DEPLOY-MANY.md)

---

## 📊 Monitoring

### Metrics & Logging
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **Azure Log Analytics**: Centralized logging
- **Application Insights**: APM and tracing

### Access Monitoring

```bash
# Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/monitoring-prometheus 9090:9090
```

---

## 🎓 Learning Outcomes

This project demonstrates:

### DevOps Practices
- ✅ CI/CD pipeline design and implementation
- ✅ GitFlow branching strategy
- ✅ Infrastructure as Code (Terraform)
- ✅ Configuration management (Helm)

### Cloud-Native Patterns
- ✅ Microservices architecture
- ✅ Container orchestration (Kubernetes)
- ✅ Service discovery and load balancing
- ✅ Autoscaling and self-healing

### Enterprise Standards
- ✅ Multi-environment strategy
- ✅ Security scanning and compliance
- ✅ Monitoring and observability
- ✅ High availability and disaster recovery

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [GITFLOW-AND-CICD.md](GITFLOW-AND-CICD.md) | Complete CI/CD and branching guide |
| [BUILD-ONCE-DEPLOY-MANY.md](BUILD-ONCE-DEPLOY-MANY.md) | DevSecOps build strategy |
| [ENVIRONMENTS.md](ENVIRONMENTS.md) | Environment configuration details |
| [HPA-IMPLEMENTATION.md](HPA-IMPLEMENTATION.md) | Autoscaling implementation |
| [HELM-FIXES-APPLIED.md](HELM-FIXES-APPLIED.md) | Helm chart improvements |
| [REQUIREMENTS-AND-SPRINT-PLAN.md](REQUIREMENTS-AND-SPRINT-PLAN.md) | Project planning and requirements |

---

## 🚀 Deployment Status

### Current Deployment
- **Environment**: Development
- **Status**: ✅ Running
- **Pods**: 12/12 Running
- **URL**: http://57.151.39.73:8080
- **Uptime**: Active

### Infrastructure
- **Cluster**: robot-shop-dev-aks
- **Nodes**: 2 × Standard_DC2s_v3
- **Region**: East US
- **Kubernetes**: 1.31.13

---

## 🤝 Contributing

This is an open-source demonstration project. Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📝 License

This project is for educational and demonstration purposes.

---

## 🙏 Acknowledgments

- **Stan's Robot Shop** - Original application by Instana
- **Azure AKS Team** - Excellent Kubernetes service
- **Open Source Community** - Tools and frameworks used

---

**⭐ This project demonstrates production-ready Platform Engineering practices**

*Built with enterprise best practices for cloud-native microservices*
