# Standardized Rhythmic tag set (team/service + terraform metadata), merged with
# user var.tags. The tags module is pure string manipulation with no provider
# requirement of its own, so it keeps this module azurerm-only. enforce_case and
# names drive the module's Name output, which locals.tf drops via tags_no_name.
module "tags" {
  source  = "rhythmictech/tags/terraform"
  version = "~> 1.1"

  enforce_case = "UPPER"
  names        = ["Rhythmic-AccountMonitoring"]

  tags = merge({
    team    = "Rhythmic"
    service = "azure_managed_services"
  }, var.tags)
}

# The subscription the module is invoked against. Its id is the scope for both
# the activity-log alert rules and the backup-failure processing rule.
data "azurerm_subscription" "current" {}

# A. Control-plane detections. One activity-log alert rule per catalog entry,
# each firing into the shared Action Group. Azure activity-log criteria are
# singular (one operation_name per rule), which is why the catalog is modelled
# as one operation per map entry.
resource "azurerm_monitor_activity_log_alert" "detections" {
  for_each = var.activity_log_detections

  name                = "${var.name_prefix}${each.key}"
  resource_group_name = var.resource_group_name
  location            = local.alert_location
  scopes              = [local.subscription_id]
  description         = each.value.description
  tags                = local.tags

  criteria {
    category       = each.value.category
    operation_name = each.value.operation_name
    level          = each.value.level
  }

  action {
    action_group_id = var.action_group_id
  }
}

# B. Backup job-failure routing. Recovery Services vaults raise Azure Backup
# alerts natively, but without a processing rule those alerts reach no Action
# Group. This subscription-scope rule attaches the shared Action Group to every
# alert whose monitor service is Azure Backup.
resource "azurerm_monitor_alert_processing_rule_action_group" "backup_failure" {
  count = var.enable_backup_failure_routing ? 1 : 0

  name                 = "${var.name_prefix}backup-failure-routing"
  resource_group_name  = var.resource_group_name
  scopes               = [local.subscription_id]
  add_action_group_ids = [var.action_group_id]
  description          = "Routes Azure Backup job-failure alerts to the shared account-alerts Action Group."
  tags                 = local.tags

  condition {
    monitor_service {
      operator = "Equals"
      values   = ["Azure Backup"]
    }
  }
}

# C. Microsoft Defender for Cloud posture. Plan enablement is opt-in (empty map
# by default) because paid plans are a deliberate per-subscription cost
# decision. One pricing resource per requested resource_type.
resource "azurerm_security_center_subscription_pricing" "plans" {
  for_each = var.defender_plans

  resource_type = each.key
  tier          = each.value.tier
  subplan       = each.value.subplan
}

# Optional Defender for Cloud security contact. Created only when an email is
# supplied.
resource "azurerm_security_center_contact" "security" {
  count = var.security_contact_email != null ? 1 : 0

  name                = var.security_contact_name
  email               = var.security_contact_email
  alert_notifications = var.security_contact_alert_notifications
  alerts_to_admins    = var.security_contact_alerts_to_admins
}
