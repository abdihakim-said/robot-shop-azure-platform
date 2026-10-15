# Sourced inside AzureCLI@2 (addSpnToEnvironment: true) so the azurerm provider and
# backend sign in with the service connection's federated token. No client secret.
export ARM_CLIENT_ID="$servicePrincipalId"
export ARM_TENANT_ID="$tenantId"
export ARM_OIDC_TOKEN="$idToken"
export ARM_USE_OIDC=true
ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export ARM_SUBSCRIPTION_ID
