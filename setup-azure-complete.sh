#!/bin/bash
set -e

# Complete Azure Setup for GitHub Actions + Key Vault
# Best Practice: Workload Identity + Key Vault for secrets

echo "🔐 Complete Azure Setup for Robot Shop Platform"
echo "=================================================="

# Configuration
GITHUB_ORG="abdihakim-said"
GITHUB_REPO="robot-shop-azure-platform"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
LOCATION="eastus"
APP_NAME="github-actions-robot-shop"
RG_NAME="robot-shop-shared-rg"
KV_NAME="robot-shop-secrets-kv"

echo "📋 Configuration:"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Tenant: $TENANT_ID"
echo "  Location: $LOCATION"
echo "  GitHub: $GITHUB_ORG/$GITHUB_REPO"
echo ""

# ============================================
# STEP 1: Create Service Principal
# ============================================
echo "1️⃣ Creating Service Principal for GitHub Actions..."

SP_OUTPUT=$(az ad app create --display-name "$APP_NAME" --query "{appId:appId,objectId:id}" -o json)
APP_ID=$(echo $SP_OUTPUT | jq -r .appId)
OBJECT_ID=$(echo $SP_OUTPUT | jq -r .objectId)

az ad sp create --id $APP_ID > /dev/null
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)

echo "   ✅ App ID: $APP_ID"
echo "   ✅ Service Principal created"

# ============================================
# STEP 2: Assign Permissions
# ============================================
echo "2️⃣ Assigning Azure permissions..."

# Contributor role for infrastructure deployment
az role assignment create \
  --role Contributor \
  --assignee $APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID \
  > /dev/null

echo "   ✅ Contributor role assigned"

# ============================================
# STEP 3: Setup Workload Identity (No Secrets!)
# ============================================
echo "3️⃣ Setting up Workload Identity (Federated Credentials)..."

# Develop branch
az ad app federated-credential create \
  --id $OBJECT_ID \
  --parameters "{
    \"name\": \"github-develop\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/develop\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" > /dev/null

# Release branches
az ad app federated-credential create \
  --id $OBJECT_ID \
  --parameters "{
    \"name\": \"github-release\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/release/*\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" > /dev/null

# Main branch
az ad app federated-credential create \
  --id $OBJECT_ID \
  --parameters "{
    \"name\": \"github-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" > /dev/null

echo "   ✅ Federated credentials created (develop, release/*, main)"

# ============================================
# STEP 4: Create Shared Resource Group
# ============================================
echo "4️⃣ Creating shared resource group..."

az group create \
  --name $RG_NAME \
  --location $LOCATION \
  --tags Environment=shared Purpose=secrets ManagedBy=terraform \
  > /dev/null

echo "   ✅ Resource group: $RG_NAME"

# ============================================
# STEP 5: Create Key Vault for Secrets
# ============================================
echo "5️⃣ Creating Azure Key Vault..."

az keyvault create \
  --name $KV_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --enable-rbac-authorization true \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true \
  > /dev/null

KV_ID=$(az keyvault show --name $KV_NAME --query id -o tsv)

echo "   ✅ Key Vault: $KV_NAME"

# ============================================
# STEP 6: Grant Key Vault Permissions
# ============================================
echo "6️⃣ Granting Key Vault permissions..."

# Service Principal needs to read secrets
az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee $APP_ID \
  --scope $KV_ID \
  > /dev/null

# Your user needs to manage secrets
CURRENT_USER=$(az ad signed-in-user show --query id -o tsv)
az role assignment create \
  --role "Key Vault Administrator" \
  --assignee $CURRENT_USER \
  --scope $KV_ID \
  > /dev/null

echo "   ✅ Permissions granted"

# ============================================
# STEP 7: Store Secrets in Key Vault
# ============================================
echo "7️⃣ Storing secrets in Key Vault..."

# Generate secure passwords
GRAFANA_PASSWORD=$(openssl rand -base64 16)
PROMETHEUS_PASSWORD=$(openssl rand -base64 16)
MYSQL_PASSWORD=$(openssl rand -base64 16)
REDIS_PASSWORD=$(openssl rand -base64 16)

# Store in Key Vault
az keyvault secret set --vault-name $KV_NAME --name "grafana-admin-password" --value "$GRAFANA_PASSWORD" > /dev/null
az keyvault secret set --vault-name $KV_NAME --name "prometheus-password" --value "$PROMETHEUS_PASSWORD" > /dev/null
az keyvault secret set --vault-name $KV_NAME --name "mysql-admin-password" --value "$MYSQL_PASSWORD" > /dev/null
az keyvault secret set --vault-name $KV_NAME --name "redis-password" --value "$REDIS_PASSWORD" > /dev/null

echo "   ✅ Secrets stored (grafana, prometheus, mysql, redis)"

# ============================================
# STEP 8: Setup GitHub Secrets
# ============================================
echo "8️⃣ Setting up GitHub secrets..."

gh secret set AZURE_CLIENT_ID --body "$APP_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set KEY_VAULT_NAME --body "$KV_NAME"

echo "   ✅ GitHub secrets configured"

# ============================================
# SUMMARY
# ============================================
echo ""
echo "=================================================="
echo "✅ Setup Complete!"
echo "=================================================="
echo ""
echo "🔐 Security Architecture:"
echo "   GitHub Actions → Workload Identity (no secrets!)"
echo "   Service Principal → Azure RBAC"
echo "   Secrets → Azure Key Vault"
echo ""
echo "📝 GitHub Secrets (already set):"
echo "   AZURE_CLIENT_ID: $APP_ID"
echo "   AZURE_TENANT_ID: $TENANT_ID"
echo "   AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "   KEY_VAULT_NAME: $KV_NAME"
echo ""
echo "🔑 Key Vault:"
echo "   Name: $KV_NAME"
echo "   Resource Group: $RG_NAME"
echo "   Secrets: grafana-admin-password, prometheus-password, mysql-admin-password, redis-password"
echo ""
echo "🎯 Next Steps:"
echo "   1. Update Terraform to read from Key Vault"
echo "   2. Update GitHub workflow to use Workload Identity"
echo "   3. Test pipeline deployment"
echo ""
echo "📋 View secrets:"
echo "   az keyvault secret list --vault-name $KV_NAME --query '[].name' -o table"
echo ""
echo "🔍 Get a secret:"
echo "   az keyvault secret show --vault-name $KV_NAME --name grafana-admin-password --query value -o tsv"
echo ""
