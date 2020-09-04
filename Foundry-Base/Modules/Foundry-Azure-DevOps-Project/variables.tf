variable "azure_devops_project" {
  type = object({
    name               = string
    areaPrefix         = string
    description        = string
    subscription_id    = string
    visibility         = string
    version_control    = string
    work_item_template = string
    repolist           = list(string)
    features = object({
      boards       = string
      repositories = string
      pipelines    = string
      testplans    = string
      artifacts    = string
    })
  })
}