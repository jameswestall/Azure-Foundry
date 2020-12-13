variable "subscription_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "tenant_id" {
  type = string
}

variable "customerName" {
  type    = string
  default = "Company"
}

variable "deployRegion" {
  type    = string
  default = "australiasoutheast"
}

variable "allowedRegions" {
  type    = string
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

variable "platformSubscriptions" {
  type    = list
  default = ["10737489-ac39-415a-bd96-e76f05732c85"]
}

variable "devSubscriptions" {
  type    = list
  default = ["9ddbb73f-7a81-4d90-b96a-ae360b43e1d8"]
}

variable "prodSubscriptions" {
  type    = list
  default = null
}