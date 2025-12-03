# 🚀 Deployment Guide

Complete step-by-step guide to deploy Robot Shop on Azure AKS.

## Prerequisites

### 1. Install Required Tools

```bash
# Azure CLI
brew install azure-cli  # macOS
# or
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Linux

# Terraform
brew install terraform

# kubectl
brew install kubectl

# Helm
brew install helm
```

### 2. Login to Azure

```bash
az login

# Set subscription (if you have multiple)
az account list --output table
az account set --subscription "Your-Subscription-Name"

# Verify
az account show
```

## Step 1: Deploy Infrastructure with Terraform

### 1.1 Navigate to Terraform Directory

```bash
cd terraform
```

### 1.2 Create terraform.tfvars

```bash
cat > terraform.tfvars <<EOF
resource_group_name    = "robot-shop-rg"
location               = "eastus"
cluster_name           = "robot-shop-aks"
node_count             = 3
vm_size                = "Standard_B2s"
environment            = "dev"
grafana_admin_password = "YourSecurePassword123!"
EOF
```

### 1.3 Initialize Terraform

```bash
terraform init
```

### 1.4 Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure everything looks correct.

### 1.5 Apply Infrastructure

```bash
terraform apply tfplan
```

This will create:
- Resource Group
- Virtual Network and Subnet
- Network Security Group
- AKS Cluster (3 nodes)
- Azure Container Registry
- Log Analytics Workspace
- Application Insights
- Prometheus + Grafana monitoring stack

**Deployment time: ~10-15 minutes**

### 1.6 Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group robot-shop-rg \
  --name robot-shop-aks
```

### 1.7 Verify Cluster

```bash
kubectl get nodes
kubectl get pods -n monitoring
```

## Step 2: Deploy Robot Shop Application

### 2.1 Create Namespace

```bash
kubectl create namespace robot-shop
```

### 2.2 Deploy with Helm

```bash
cd ../helm
helm install robot-shop \
  --namespace robot-shop \
  --values values-azure.yaml \
  .
```

### 2.3 Check Deployment

```bash
# Watch pods starting
kubectl get pods -n robot-shop -w

# Check all pods are running
kubectl get pods -n robot-shop

# Check services
kubectl get svc -n robot-shop
```

### 2.4 Get Application URL

```bash
# Get web service LoadBalancer IP
kubectl get svc -n robot-shop web

# Or use this command
kubectl get svc -n robot-shop web -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Wait 2-3 minutes for the LoadBalancer to provision, then access:
```
http://<EXTERNAL-IP>:8080
```

## Step 3: Access Monitoring

### 3.1 Get Grafana URL

```bash
# Get Grafana LoadBalancer IP
kubectl get svc -n monitoring monitoring-grafana

# Or
kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### 3.2 Login to Grafana

```
URL: http://<GRAFANA-IP>
Username: admin
Password: <from terraform.tfvars>
```

### 3.3 View Pre-installed Dashboards

Navigate to:
- Dashboards → Kubernetes Cluster Monitoring
- Dashboards → Kubernetes Pods
- Dashboards → Node Exporter

### 3.4 Access Prometheus (Optional)

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Open browser
open http://localhost:9090
```

## Step 4: Verification

### 4.1 Test Application

```bash
# Get web URL
WEB_URL=$(kubectl get svc -n robot-shop web -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test homepage
curl http://$WEB_URL:8080

# Test catalogue API
curl http://$WEB_URL:8080/api/catalogue
```

### 4.2 Check Logs

```bash
# Web service logs
kubectl logs -n robot-shop -l app=web

# All services logs
kubectl logs -n robot-shop --all-containers=true --tail=50
```

### 4.3 Check Metrics in Prometheus

```bash
# Port forward
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Query examples:
# - kube_pod_status_phase{namespace="robot-shop"}
# - container_memory_usage_bytes{namespace="robot-shop"}
# - rate(container_cpu_usage_seconds_total{namespace="robot-shop"}[5m])
```

## Step 5: Terraform Outputs

```bash
cd terraform

# View all outputs
terraform output

# Get specific output
terraform output grafana_admin_password
terraform output acr_login_server
terraform output get_credentials_command
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod
kubectl describe pod -n robot-shop <pod-name>

# Check events
kubectl get events -n robot-shop --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n robot-shop <pod-name>
```

### LoadBalancer Pending

```bash
# Check service
kubectl describe svc -n robot-shop web

# Check Azure Load Balancer
az network lb list --resource-group MC_robot-shop-rg_robot-shop-aks_eastus
```

### Monitoring Not Working

```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/targets

# Check Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

## Cleanup

### Delete Application Only

```bash
helm uninstall robot-shop -n robot-shop
kubectl delete namespace robot-shop
```

### Delete Everything

```bash
cd terraform
terraform destroy
```

### Or Delete Resource Group

```bash
az group delete --name robot-shop-rg --yes --no-wait
```

## Cost Management

### Stop Cluster (Save Costs)

```bash
az aks stop --resource-group robot-shop-rg --name robot-shop-aks
```

### Start Cluster

```bash
az aks start --resource-group robot-shop-rg --name robot-shop-aks
```

### Check Costs

```bash
# View cost analysis in Azure Portal
az portal open --resource-group robot-shop-rg
```

## Next Steps

1. **Add CI/CD Pipeline** - Automate deployments
2. **Configure Custom Alerts** - Set up email notifications
3. **Add Custom Dashboards** - Create service-specific views
4. **Implement GitOps** - Use ArgoCD or Flux
5. **Add Service Mesh** - Implement Istio or Linkerd

---

**Deployment Complete!** 🎉

Your Robot Shop is now running on Azure AKS with full monitoring.
