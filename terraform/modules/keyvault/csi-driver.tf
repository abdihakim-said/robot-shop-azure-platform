# Enable Key Vault CSI driver on AKS
# This allows pods to mount secrets from Key Vault as volumes

resource "null_resource" "install_csi_driver" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/deployment/provider-azure-installer.yaml
    EOT
  }
  
  depends_on = [azurerm_key_vault.main]
}
