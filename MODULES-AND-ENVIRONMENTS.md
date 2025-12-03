# 🏗️ Terraform Modules & Environments Architecture

## ✅ Azure Best Practices Implemented

This project follows **Azure Well-Architected Framework** and **Terraform best practices**:

### 1. **Modular Architecture**
- Reusable, composable modules
- Separation of concerns
- DRY (Don't Repeat Yourself) principle

### 2. **Environment Separation**
- Dev, Staging, Prod environments
- Environment-specific configurations
- Different resource sizing per environment

### 3. **State Management**
- Remote state backend support (Azure Storage)
- State locking
- Environment isolation

### 4. **Security**
- No hardcoded credentials
- Sensitive values marked as sensitive
- Azure Managed Identity

### 5. **Cost Optimization**
- Environment-appropriate sizing
- Dev: Smaller, cost-effective resources
- Prod: Larger, HA resources

---

## 📁 New Project Structure

```
terraform/
├── modules/                        # Reusable modules
│   ├── aks/                       # AKS cluster module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── networking/                # Networking module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── monitoring/                # Monitoring module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/                   # Storage module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/                   # Environment-specific configs
│   ├── dev/                       # Development
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   ├── staging/                   # Staging (optional)
│   │   └── ...
│   └── prod/                      # Production
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
│
└── helm-values/                    # Helm value templates
    └── prometheus-values.yaml
```

---

## 🎯 Module Breakdown

### **1. AKS Module** (`modules/aks/`)

**Purpose:** Manages AKS cluster and Log Analytics

**Resources:**
- AKS cluster with autoscaling
- Log Analytics workspace
- Container Insights integration
- Azure Policy integration

**Inputs:**
- Cluster name, location, resource group
- Node configuration (count, size, autoscaling)
- Kubernetes version
- Network configuration

**Outputs:**
- Cluster ID and name
- Kube config
- Kubelet identity
- Log Analytics workspace ID

---

### **2. Networking Module** (`modules/networking/`)

**Purpose:** Manages VNet, subnets, and NSG

**Resources:**
- Virtual Network
- AKS subnet
- Network Security Group
- NSG association

**Inputs:**
- Name prefix, location, resource group
- VNet address space
- Subnet prefixes
- Security rules (configurable)

**Outputs:**
- VNet ID and name
- Subnet ID
- NSG ID

---

### **3. Monitoring Module** (`modules/monitoring/`)

**Purpose:** Manages Azure Monitor and alerts

**Resources:**
- Application Insights
- Action Group (for alerts)
- Diagnostic Settings

**Inputs:**
- Name prefix, location, resource group
- Log Analytics workspace ID
- AKS cluster ID
- Alert email addresses

**Outputs:**
- Application Insights ID and key
- Action Group ID

---

### **4. Storage Module** (`modules/storage/`)

**Purpose:** Manages ACR and Storage Account

**Resources:**
- Azure Container Registry
- Storage Account
- ACR role assignment for AKS

**Inputs:**
- ACR and storage account names
- Location, resource group
- Kubelet identity for ACR pull
- SKU and replication settings

**Outputs:**
- ACR ID and login server
- Storage account ID and name

---

## 🌍 Environment Configurations

### **Development Environment**

**Purpose:** Cost-effective environment for development and testing

**Configuration:**
```hcl
node_count         = 2
vm_size            = "Standard_B2s"
min_node_count     = 1
max_node_count     = 3
acr_sku            = "Basic"
storage_replication = "LRS"
prometheus_storage = "10Gi"
```

**Cost:** ~$60-80/month

---

### **Production Environment**

**Purpose:** High-availability, production-ready environment

**Configuration:**
```hcl
node_count         = 5
vm_size            = "Standard_D2s_v3"
min_node_count     = 3
max_node_count     = 10
acr_sku            = "Premium"
storage_replication = "GRS"
prometheus_storage = "50Gi"
```

**Cost:** ~$300-400/month

---

## 🚀 Deployment Guide

### **Deploy Development Environment**

```bash
# 1. Navigate to dev environment
cd terraform/environments/dev

# 2. Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# 3. Initialize Terraform
terraform init

# 4. Plan
terraform plan -out=tfplan

# 5. Apply
terraform apply tfplan

# 6. Get credentials
az aks get-credentials \
  --resource-group robot-shop-dev-rg \
  --name robot-shop-dev-aks
```

### **Deploy Production Environment**

```bash
# 1. Navigate to prod environment
cd terraform/environments/prod

# 2. Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# 3. Initialize Terraform
terraform init

# 4. Plan
terraform plan -out=tfplan

# 5. Apply
terraform apply tfplan

# 6. Get credentials
az aks get-credentials \
  --resource-group robot-shop-prod-rg \
  --name robot-shop-prod-aks
```

---

## 🔄 Remote State Configuration (Optional)

### **Setup Azure Storage for State**

```bash
# Create storage account for Terraform state
az group create --name terraform-state-rg --location eastus

az storage account create \
  --name tfstaterobotshop \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name tfstaterobotshop
```

### **Enable Remote State in main.tf**

Uncomment the backend block in `environments/*/main.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "terraform-state-rg"
  storage_account_name = "tfstaterobotshop"
  container_name       = "tfstate"
  key                  = "dev.terraform.tfstate"  # or prod.terraform.tfstate
}
```

---

## 📊 Environment Comparison

| Feature | Dev | Prod |
|---------|-----|------|
| **Nodes** | 2 (1-3) | 5 (3-10) |
| **VM Size** | Standard_B2s | Standard_D2s_v3 |
| **ACR SKU** | Basic | Premium |
| **Storage** | LRS | GRS |
| **Prometheus** | 10Gi | 50Gi |
| **Grafana** | 5Gi | 20Gi |
| **Cost/Month** | ~$60-80 | ~$300-400 |

---

## ✅ Benefits of This Architecture

### **1. Reusability**
- Modules can be used across multiple projects
- Consistent infrastructure patterns
- Easy to maintain and update

### **2. Environment Isolation**
- Separate state files per environment
- Different configurations per environment
- No risk of dev changes affecting prod

### **3. Scalability**
- Easy to add new environments (staging, QA)
- Simple to adjust resource sizing
- Module versioning support

### **4. Best Practices**
- Follows Azure Well-Architected Framework
- Terraform module best practices
- Infrastructure as Code principles

### **5. Cost Optimization**
- Right-sized resources per environment
- Dev environment can be stopped when not in use
- Clear cost attribution per environment

---

## 🎯 Interview Talking Points

**"I implemented a production-grade Terraform architecture following Azure best practices:**

1. **Modular Design**
   - Created reusable modules for AKS, networking, monitoring, and storage
   - Each module is self-contained with clear inputs/outputs
   - Promotes code reusability and maintainability

2. **Environment Separation**
   - Separate configurations for dev and prod
   - Environment-specific resource sizing
   - Dev uses cost-effective resources, prod uses HA configuration

3. **State Management**
   - Support for remote state in Azure Storage
   - State locking to prevent concurrent modifications
   - Environment isolation with separate state files

4. **Azure Best Practices**
   - Follows Well-Architected Framework
   - Proper tagging strategy
   - Cost center attribution
   - Security best practices (Managed Identity, no hardcoded credentials)

5. **Scalability**
   - Easy to add new environments
   - Module versioning support
   - Can be extended to multi-region deployments"

---

## 🔧 Module Usage Example

```hcl
# Using the AKS module
module "aks" {
  source = "../../modules/aks"

  cluster_name        = "my-cluster"
  location            = "eastus"
  resource_group_name = "my-rg"
  subnet_id           = module.networking.aks_subnet_id
  
  node_count = 3
  vm_size    = "Standard_D2s_v3"
  
  tags = {
    Environment = "production"
    Project     = "robot-shop"
  }
}
```

---

## 📚 Next Steps

1. **Deploy Dev Environment** - Test the setup
2. **Customize Modules** - Adjust to your needs
3. **Add Staging** - Create staging environment
4. **Setup Remote State** - Enable state backend
5. **Add CI/CD** - Automate deployments

---

**This architecture demonstrates enterprise-level Terraform and Azure expertise!** 🚀
