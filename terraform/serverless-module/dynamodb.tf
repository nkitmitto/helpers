module dynamodb_module {
  project_name = var.project_name
  environment = var.environment

  for_each = var.provisioned_datasets
  source = "./dynamodb_module"
  dataSourceName = each.key
  attributes = each.value.attributes
  hash_key = each.value.hash_key
}