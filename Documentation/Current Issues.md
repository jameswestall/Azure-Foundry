# Current Issue List
The following list of issues have been identified in development of this solution. Without utilizing further tooling or products, these items are waiting for upstream support. 

### Multiple provider blocks required, provider looping not supported in Terraform

**Upstream Issue(s):**
https://github.com/hashicorp/terraform/issues/25244
https://github.com/hashicorp/terraform/issues/19932

**Ideal Code set:**
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

**Notes:**
N/A


### Unable to provision subscriptions, requiring manual provisioning

**Upstream Issue(s):**
https://github.com/terraform-providers/terraform-provider-azurerm/issues/1216


**Ideal Code set:**
```
module "Foundry-Subscription" {
  for_each        = var.foundry_project_list
  source          = "./Modules/Foundry-Azure-Subscription"
  subscriptionName = each.value.name
  tenant_id       = var.tenant_id
}
```

**Notes:**
This is supported via ARM, so you could technically complete this with a nested template, however that functionality is reserved for EA customers, reducing compatibility of the solution. 
Would depend on dynamic provisioning of a provider, likely the looping issue listed above. 