# Staging & Production Requirements

## Key Differences from Dev

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Access** | Public IP:8080 | Custom DNS + HTTPS | Custom DNS + HTTPS |
| **DNS** | None | staging.domain.com | domain.com |
| **TLS/SSL** | None | Let's Encrypt | Let's Encrypt/Azure Cert |
| **Ingress** | LoadBalancer | Nginx Ingress | Nginx Ingress + WAF |
| **Secrets** | ConfigMaps | Azure Key Vault | Azure Key Vault |
| **Network** | Basic NSG | Stricter NSG | Private endpoints |
| **Monitoring** | Basic | Enhanced alerts | 24/7 alerts + PagerDuty |
| **Backup** | None | Daily | Hourly + geo-redundant |
| **Nodes** | 2 | 3 | 5 |
| **Autoscaling** | 2-4 | 2-5 | 3-10 |

---

## 1. DNS Configuration

### Azure DNS Zone
```hcl
# terraform/modules/networking/dns.tf
resource "azurerm_dns_zone" "main" {
  name                = var.domain_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_a_record" "web" {
  name                = var.environment == "prod" ? "@" : var.environment
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [kubernetes_service.web_lb_ip]
}
```

**Result:**
- Dev: `57.151.39.73:8080`
- Staging: `https://staging.robotshop.com`
- Prod: `https://robotshop.com`

---

## 2. Ingress Controller + TLS

### Install Nginx Ingress
```bash
# Add to Terraform or Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

### Cert-Manager for Let's Encrypt
```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### Ingress Resource
```yaml
# helm/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: robot-shop-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - {{ .Values.domain }}
    secretName: robot-shop-tls
  rules:
  - host: {{ .Values.domain }}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 8080
```

---

## 3. Azure Key Vault Integration

### Terraform Module
```hcl
# terraform/modules/security/keyvault.tf
resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-${var.environment}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = var.environment == "prod" ? true : false
}

# Store secrets
resource "azurerm_key_vault_secret" "grafana_password" {
  name         = "grafana-admin-password"
  value        = random_password.grafana.result
  key_vault_id = azurerm_key_vault.main.id
}
```

### CSI Driver for K8s
```yaml
# Use Azure Key Vault CSI driver to mount secrets
apiVersion: v1
kind: SecretProviderClass
metadata:
  name: azure-kvname
spec:
  provider: azure
  parameters:
    keyvaultName: "robot-shop-prod-kv"
    objects: |
      array:
        - |
          objectName: grafana-admin-password
          objectType: secret
```

---

## 4. Enhanced Security (NSG)

### Staging NSG Rules
```hcl
# Only allow HTTPS from internet
security_rule {
  name                       = "allow-https"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# Allow HTTP for Let's Encrypt challenge
security_rule {
  name                       = "allow-http-letsencrypt"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

### Production NSG Rules
```hcl
# Whitelist specific IPs (office, VPN)
security_rule {
  name                       = "allow-https-office"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefixes    = ["203.0.113.0/24", "198.51.100.0/24"]  # Office IPs
  destination_address_prefix = "*"
}
```

---

## 5. Private Endpoints (Prod)

### Database Private Endpoints
```hcl
# Keep databases internal only
resource "azurerm_private_endpoint" "mongodb" {
  name                = "${var.project_name}-mongodb-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private.id

  private_service_connection {
    name                           = "mongodb-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.mongodb.id
    is_manual_connection           = false
  }
}
```

---

## 6. WAF (Production)

### Azure Application Gateway + WAF
```hcl
resource "azurerm_application_gateway" "main" {
  name                = "${var.project_name}-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}
```

---

## 7. Monitoring & Alerts

### Production Alerts
```yaml
# Enhanced Prometheus alerts for prod
groups:
- name: production-critical
  rules:
  - alert: PodDown
    expr: up{job="kubernetes-pods"} == 0
    for: 1m
    annotations:
      summary: "Pod {{ $labels.pod }} is down"
      severity: critical
  
  - alert: HighMemoryUsage
    expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
    for: 5m
    annotations:
      summary: "High memory usage on {{ $labels.pod }}"
      severity: warning
```

---

## Implementation Order

### Phase 1: Staging (2-3 hours)
1. ✅ Add Nginx Ingress Controller
2. ✅ Add Cert-Manager
3. ✅ Configure DNS (Azure DNS or external)
4. ✅ Create Ingress resource with TLS
5. ✅ Test HTTPS access

### Phase 2: Security (1-2 hours)
1. ✅ Add Azure Key Vault module
2. ✅ Migrate secrets to Key Vault
3. ✅ Update NSG rules (stricter)
4. ✅ Add CSI driver for secret mounting

### Phase 3: Production (1 hour)
1. ✅ Add WAF (Application Gateway)
2. ✅ Configure private endpoints
3. ✅ Set up backup policies
4. ✅ Configure 24/7 alerting

---

## Quick Start Commands

### Deploy Staging with DNS + HTTPS
```bash
cd terraform/environments/staging

# Edit terraform.tfvars
cat >> terraform.tfvars <<EOF
domain_name = "robotshop.yourdomain.com"
enable_ingress = true
enable_tls = true
EOF

terraform init
terraform apply

# Install ingress + cert-manager
kubectl apply -f ../../modules/ingress/
```

### Deploy Production
```bash
cd terraform/environments/prod

# Edit terraform.tfvars
cat >> terraform.tfvars <<EOF
domain_name = "robotshop.com"
enable_ingress = true
enable_tls = true
enable_waf = true
enable_private_endpoints = true
EOF

terraform init
terraform apply
```

---

## Cost Impact

| Environment | Monthly Cost | Key Additions |
|-------------|--------------|---------------|
| Dev | ~$80 | Basic setup |
| Staging | ~$200 | + Ingress, DNS, Cert-Manager |
| Production | ~$500 | + WAF, Private Endpoints, Premium ACR |

---

## Next Steps

**Choose your path:**

1. **Quick Demo (30 min):** Add ingress + TLS to dev for demo purposes
2. **Full Staging (2-3 hours):** Implement all staging requirements
3. **Production Ready (4-5 hours):** Full prod setup with WAF + private endpoints

**Which would you like to implement?**
