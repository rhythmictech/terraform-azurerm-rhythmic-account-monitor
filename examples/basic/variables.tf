variable "subscription_id" {
  description = "Azure subscription id the account monitoring is deployed into."
  type        = string
}

variable "action_group_id" {
  description = "Resource ID of the account-alerts Action Group detections fire into."
  type        = string
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rhythmic-monitoring/providers/microsoft.insights/actionGroups/rhythmic-accountalerts"
}

variable "resource_group_name" {
  description = "Name of the existing resource group the alert rules are created in."
  type        = string
  default     = "rhythmic-monitoring"
}
