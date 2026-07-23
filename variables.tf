variable "action_group_id" {
  description = "Resource ID of the shared account-alerts Action Group every detection fires into (typically the rhythmic-core module's account_action_group_id output)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the (existing) resource group the activity-log alert rules are created in (typically the rhythmic-core module's resource_group_name output)."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names created by this module."
  type        = string
  default     = "rhythmic-"
}

variable "activity_log_detections" {
  description = "Control-plane detections rendered as activity-log alert rules wired to the Action Group. Keys are rule name suffixes. Override the whole map to replace the curated catalog. category is required; operation_name narrows to a single control-plane operation (leave null for a category-wide rule); level optionally filters by severity."
  type = map(object({
    category       = string
    operation_name = optional(string)
    level          = optional(string)
    description    = string
  }))

  default = {
    role-assignment-created = {
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/roleAssignments/write"
      description    = "A role assignment was created (privilege grant)."
    }
    role-assignment-deleted = {
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/roleAssignments/delete"
      description    = "A role assignment was deleted (privilege revocation)."
    }
    policy-assignment-created = {
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/policyAssignments/write"
      description    = "A policy assignment was created or updated."
    }
    policy-assignment-deleted = {
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/policyAssignments/delete"
      description    = "A policy assignment was deleted."
    }
    defender-plan-changed = {
      category       = "Administrative"
      operation_name = "Microsoft.Security/pricings/write"
      description    = "A Microsoft Defender for Cloud plan tier was changed (guards against silent downgrades)."
    }
    recovery-vault-deleted = {
      category       = "Administrative"
      operation_name = "Microsoft.RecoveryServices/vaults/delete"
      description    = "A Recovery Services vault was deleted."
    }
    backup-policy-changed = {
      category       = "Administrative"
      operation_name = "Microsoft.RecoveryServices/vaults/backupPolicies/write"
      description    = "A Recovery Services backup policy was created or modified."
    }
    policy-noncompliance = {
      category       = "Policy"
      operation_name = null
      level          = "Warning"
      description    = "Azure Policy reported a compliance state change."
    }
  }

  validation {
    condition     = alltrue([for k, v in var.activity_log_detections : length(trimspace(v.category)) > 0])
    error_message = "Every activity_log_detections entry must set a non-empty category (activity-log alert criteria require one)."
  }
}

variable "enable_backup_failure_routing" {
  description = "Create a subscription-scope alert processing rule that attaches the Action Group to Azure Backup's built-in job-failure alerts (Recovery Services vaults emit these natively; without a processing rule they route nowhere)."
  type        = bool
  default     = true
}

variable "defender_plans" {
  description = "Microsoft Defender for Cloud plans to enable on the subscription, keyed by resource_type (e.g. VirtualMachines, AppServices, SqlServers, StorageAccounts). Empty by default: enabling paid plans is a deliberate per-client cost decision."
  type = map(object({
    tier    = optional(string, "Standard")
    subplan = optional(string)
  }))
  default = {}
}

variable "security_contact_email" {
  description = "Email for the Defender for Cloud security contact. null skips creating the contact."
  type        = string
  default     = null
}

variable "security_contact_name" {
  description = "Name of the Defender for Cloud security contact resource. Azure validates the accepted value at apply time; the default matches the canonical single-contact name."
  type        = string
  default     = "default1"
}

variable "security_contact_alert_notifications" {
  description = "Whether the security contact receives email notifications for alerts."
  type        = bool
  default     = true
}

variable "security_contact_alerts_to_admins" {
  description = "Whether subscription administrators also receive the security contact's alert notifications."
  type        = bool
  default     = true
}

variable "tags" {
  description = "User-defined tags merged onto all taggable resources."
  type        = map(string)
  default     = {}
}
