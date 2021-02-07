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


### No "Deny all" rulesets implemented for firewalls

**Upstream Issue(s):**
N/A - Product Feature missing
https://feedback.azure.com/forums/217313-networking/suggestions/38926432-massive-facepalm-microsoft-how-about-enabling-ns 

**Ideal Code set:**
```
  # support for this service is currently missing from Azure Firewall. 
  # rule {
  #   name                  = "Allow-DNS-Tag"
  #   source_addresses      = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  #   destination_ports     = ["53"]
  #   destination_addresses = ["AzurePlatformDNS"]
  #   protocols             = ["TCP", "UDP"]
  # }
```

**Notes:**
Currently deny all rules are available to be implemented manually with holes punched through the firewall for each service. EG. Access to the Microsoft KMS can be achieved by placing an allow rule for 23.102.135.246 at a higher precedence than the firewall. 
Ideally, we would like to use service tags to complete this task, as it allows Microsoft to update records within the tag and does not add burden to the platform engineering team/employee. 

Some service tag functionality has not been marked as supported by Microsoft yet, namely IMDS, DNS and LKM (KMS)
https://docs.microsoft.com/en-us/azure/virtual-network/service-tags-overview#available-service-tags

As such, no deny all ruleset has been added yet. 
