/*variable "subscription_id" {
  type    = string
}
variable "client_id" {
  type    = string
}
variable "client_secret" {
  type    = string
}
variable "tenant_id" {
  type    = string
}  */

variable "customerName" {
  type    = string
  default = "Company"
}

variable "deployRegion" {
  type    = string
  default = "australiasoutheast"
}

variable "deployRegionTimeZone" {
  type    = string
  default = "E. Australia Standard Time"
}

variable "allowedRegions" {
  type = string
  default = "[\"Australia SouthEast\",\"Australia East\"]"
}

variable "tagList" {
  type = list
  default = [
    "Environment",
    "BillingCode",
    "Service",
    "Owner",
    "ExpiryDate",
    "CreationTicket"
  ]
}