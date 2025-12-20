output "backend_resource_group_name" {
  value = module.backend.resource_group_name
}

output "backend_storage_account_name" {
  value = module.backend.storage_account_name
}

output "backend_container_name" {
  value = module.backend.container_name
}

output "random_suffix" {
  value = random_string.suffix.result
}
