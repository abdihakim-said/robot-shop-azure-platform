terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Trigger pipeline - fixed YAML syntax error
# Generate random suffix for globally unique ACR name
resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_container_registry" "main" {
  name                = "${var.acr_name}${random_string.acr_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false # CKV_AZURE_137: CI uses `az acr login`, AKS uses AcrPull
  # Premium-SKU features. The registry is Basic to keep the platform cheap to run.
  #checkov:skip=CKV_AZURE_139:Private networking needs the Premium SKU. AKS pulls through its kubelet identity (AcrPull).
  #checkov:skip=CKV_AZURE_164:Content trust needs the Premium SKU. Images are built and scanned (Trivy, SBOM) in CI before push.
  #checkov:skip=CKV_AZURE_165:Geo-replication needs the Premium SKU; the platform runs in one region.
  #checkov:skip=CKV_AZURE_166:Quarantine needs the Premium SKU. The Trivy gate in CI blocks fixable CRITICAL CVEs before push.
  #checkov:skip=CKV_AZURE_167:Untagged-manifest retention needs the Premium SKU.
  #checkov:skip=CKV_AZURE_233:Zone redundancy needs the Premium SKU.
  #checkov:skip=CKV_AZURE_237:Dedicated data endpoints need the Premium SKU.
  #checkov:skip=CKV_AZURE_163:Images are scanned with Trivy in CI (build-and-push.yml); Defender for Containers is not enabled, to avoid its cost.

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.kubelet_identity_object_id
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = "GRS" # Production-grade geo-redundant storage (CKV_AZURE_206)

  # Security: Use latest TLS version (CKV_AZURE_44)
  min_tls_version = "TLS1_2"

  # CKV_AZURE_190 / CKV2_AZURE_47: no anonymous blob access
  allow_nested_items_to_be_public = false

  #checkov:skip=CKV_AZURE_59:Terraform manages blob and queue properties through the data plane from GitHub-hosted runners, which have no fixed IPs.
  #checkov:skip=CKV_AZURE_43:The name is built from a prefix and a random suffix, which Checkov cannot resolve. The variable validation enforces Azure's naming rules.
  #checkov:skip=CKV2_AZURE_1:Microsoft-managed keys are enough here; customer-managed keys need a Key Vault key and rotation process.
  #checkov:skip=CKV2_AZURE_33:Private endpoints need self-hosted runners for Terraform to reach the account (see CKV_AZURE_59).
  #checkov:skip=CKV2_AZURE_40:The azurerm provider manages the data-plane properties with the account key.

  # CKV2_AZURE_41: shared keys stay on (see CKV2_AZURE_40), so SAS tokens expire after a day
  shared_access_key_enabled = true
  sas_policy {
    expiration_period = "01.00:00:00"
  }

  blob_properties {
    delete_retention_policy {
      days = var.blob_retention_days
    }
  }

  # CKV_AZURE_33: log queue reads, writes and deletes
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }

  tags = var.tags
}
