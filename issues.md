## multiple provider blocks required due to open feature requests with terraform. 
https://github.com/hashicorp/terraform/issues/25244
https://github.com/hashicorp/terraform/issues/19932

Ideal Code set:

```
module "Foundry-Project-Areas" {
  for_each        = var.foundry_project_list
  source          = "./Modules/Foundry-Azure-Spoke"
  subscription_id = each.value.subscription_id
  areaPrefix      = each.value.areaPrefix
  customerName    = var.customerName
  deployRegion    = var.deployRegion
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
```


## Unable to provision subscriptions due to open requests with MSFT
https://github.com/terraform-providers/terraform-provider-azurerm/issues/1216

Supported via ARM, still unable to be completed with TF due to detailed requirements regarding provider testing.