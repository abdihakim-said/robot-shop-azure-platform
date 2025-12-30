#!/bin/bash
set -e

# Setup Terraform Remote State in Azure Storage
# Best Practice: Centralized state with locking

echo "📦 Setting up Terraform Remote State"
echo "=================================================="

# Configuration
RG_NAME="robot-shop-tfstate-rg"
STORAGE_ACCOUNT="robotshoptfstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

echo "📋 Configuration:"
echo "  Resource Group: $RG_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER_NAME"
echo ""

# Step 1: Create Resource Group
echo "1️⃣ Creating resource group for Terraform state..."
az group create \
  --name $RG_NAME \
  --location $LOCATION \
  --tags Purpose=terraform-state ManagedBy=manual \
  > /dev/null

echo "   ✅ Resource group created"

# Step 2: Create Storage Account
echo "2️⃣ Creating storage account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  > /dev/null

echo "   ✅ Storage account created"

# Step 3: Create Container
echo "3️⃣ Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login \
  > /dev/null

echo "   ✅ Container created"

# Step 4: Enable Versioning (for state history)
echo "4️⃣ Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true \
  > /dev/null

echo "   ✅ Versioning enabled"

# Step 5: Grant Service Principal access
echo "5️⃣ Granting Service Principal access to state..."
SP_ID=$(az ad sp list --display-name "github-actions-robot-shop" --query "[0].id" -o tsv)
STORAGE_ID=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RG_NAME --query id -o tsv)

az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $SP_ID \
  --scope $STORAGE_ID \
  > /dev/null

echo "   ✅ Permissions granted"

# Step 6: Set GitHub secrets
echo "6️⃣ Setting GitHub secrets..."
gh secret set TF_STATE_RESOURCE_GROUP --body "$RG_NAME"
gh secret set TF_STATE_STORAGE_ACCOUNT --body "$STORAGE_ACCOUNT"
gh secret set TF_STATE_CONTAINER --body "$CONTAINER_NAME"

echo "   ✅ GitHub secrets configured"

# Step 7: Create backend config files
echo "7️⃣ Creating backend configuration files..."

for ENV in dev staging production; do
  cat > terraform/environments/$ENV/backend.tf <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RG_NAME"
    storage_account_name = "$STORAGE_ACCOUNT"
    container_name       = "$CONTAINER_NAME"
    key                  = "$ENV.terraform.tfstate"
    use_azuread_auth     = true  # Uses Workload Identity
  }
}
EOF
  echo "   ✅ Created backend.tf for $ENV"
done

echo ""
echo "=================================================="
echo "✅ Terraform Remote State Setup Complete!"
echo "=================================================="
echo ""
echo "📦 State Storage:"
echo "   Resource Group: $RG_NAME"
echo "   Storage Account: $STORAGE_ACCOUNT"
echo "   Container: $CONTAINER_NAME"
echo ""
echo "🔐 Security:"
echo "   ✅ Encryption at rest enabled"
echo "   ✅ HTTPS only"
echo "   ✅ TLS 1.2 minimum"
echo "   ✅ Blob versioning enabled (state history)"
echo "   ✅ No public access"
echo "   ✅ Workload Identity authentication"
echo ""
echo "📝 State Files:"
echo "   dev.terraform.tfstate"
echo "   staging.terraform.tfstate"
echo "   production.terraform.tfstate"
echo ""
echo "🎯 Next Steps:"
echo "   1. Commit backend.tf files"
echo "   2. Run 'terraform init' to migrate state"
echo "   3. Pipeline will now use remote state"
echo ""
echo "📋 View state files:"
echo "   az storage blob list --account-name $STORAGE_ACCOUNT --container-name $CONTAINER_NAME --auth-mode login --query '[].name' -o table"
echo ""
