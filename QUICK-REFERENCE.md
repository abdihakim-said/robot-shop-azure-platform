# 🚀 Quick Reference Guide

## Environment Deployment Commands

### **Development Environment**

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Get credentials
az aks get-credentials --resource-group robot-shop-dev-rg --name robot-shop-dev-aks

# Deploy app
kubectl create namespace robot-shop
helm install robot-shop --namespace robot-shop ../../../helm
```

**Cost:** ~$60-80/month | **Nodes:** 2 (1-3) | **VM:** Standard_B2s

---

### **Staging Environment**

```bash
cd terraform/environments/staging
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Get credentials
az aks get-credentials --resource-group robot-shop-staging-rg --name robot-shop-staging-aks

# Deploy app
kubectl create namespace robot-shop
helm install robot-shop --namespace robot-shop ../../../helm
```

**Cost:** ~$150-200/month | **Nodes:** 3 (2-5) | **VM:** Standard_D2s_v3

---

### **Production Environment**

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Get credentials
az aks get-credentials --resource-group robot-shop-prod-rg --name robot-shop-prod-aks

# Deploy app
kubectl create namespace robot-shop
helm install robot-shop --namespace robot-shop ../../../helm
```

**Cost:** ~$300-400/month | **Nodes:** 5 (3-10) | **VM:** Standard_D2s_v3

---

## Common Commands

### **Get Grafana URL**
```bash
kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### **Get Application URL**
```bash
kubectl get svc -n robot-shop web -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### **Check Pods**
```bash
kubectl get pods -n robot-shop
kubectl get pods -n monitoring
```

### **View Logs**
```bash
kubectl logs -n robot-shop -l app=web
```

### **Stop Cluster (Dev only)**
```bash
az aks stop --resource-group robot-shop-dev-rg --name robot-shop-dev-aks
```

### **Start Cluster**
```bash
az aks start --resource-group robot-shop-dev-rg --name robot-shop-dev-aks
```

---

## Environment Comparison

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| **Nodes** | 2 (1-3) | 3 (2-5) | 5 (3-10) |
| **VM** | B2s | D2s_v3 | D2s_v3 |
| **ACR** | Basic | Standard | Premium |
| **Storage** | LRS | GRS | GRS |
| **Cost** | $60-80 | $150-200 | $300-400 |

---

## Troubleshooting

### **Pods Not Starting**
```bash
kubectl describe pod -n robot-shop <pod-name>
kubectl get events -n robot-shop --sort-by='.lastTimestamp'
```

### **LoadBalancer Pending**
```bash
kubectl describe svc -n robot-shop web
```

### **Terraform Errors**
```bash
terraform init -upgrade
terraform plan
```

---

## Cleanup

### **Delete Application**
```bash
helm uninstall robot-shop -n robot-shop
kubectl delete namespace robot-shop
```

### **Delete Infrastructure**
```bash
cd terraform/environments/<env>
terraform destroy
```

### **Delete Everything**
```bash
az group delete --name robot-shop-<env>-rg --yes
```

---

## Documentation Links

- **[README.md](README.md)** - Main overview
- **[ENVIRONMENTS.md](ENVIRONMENTS.md)** - Environment strategy
- **[MODULES-AND-ENVIRONMENTS.md](MODULES-AND-ENVIRONMENTS.md)** - Architecture
- **[docs/deployment-guide.md](docs/deployment-guide.md)** - Detailed guide

---

**Quick reference for deploying and managing all three environments!** 🚀
