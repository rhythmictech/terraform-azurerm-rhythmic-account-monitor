mock_provider "azurerm" {
  source = "./tests/setup"
}

# Default happy path: the curated catalog renders as activity-log alert rules,
# the backup-failure processing rule is created (default true), and no Defender
# pricing or contact resources exist (opt-in, both default off).
run "defaults" {
  command = plan

  variables {
    action_group_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rhythmic-monitoring/providers/microsoft.insights/actionGroups/rhythmic-accountalerts"
    resource_group_name = "rhythmic-monitoring"
  }

  # The curated catalog ships exactly nine control-plane detections.
  assert {
    condition     = length(azurerm_monitor_activity_log_alert.detections) == 9
    error_message = "the default detection catalog should render exactly 9 activity-log alert rules"
  }

  # Stopping backup protection is a write on the protected item, not a failed
  # job, so the catalog watches that operation with no level filter: the
  # events are Informational.
  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["backup-protection-changed"].criteria[0].operation_name == "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems/write"
    error_message = "backup-protection-changed should target the protectedItems/write operation"
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["backup-protection-changed"].criteria[0].level == null
    error_message = "backup-protection-changed must not filter on level; protection changes log as Informational"
  }

  # Every detection fires into the shared Action Group.
  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["role-assignment-created"].action[0].action_group_id == var.action_group_id
    error_message = "role-assignment-created should fire into the supplied action_group_id"
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["policy-noncompliance"].action[0].action_group_id == var.action_group_id
    error_message = "policy-noncompliance should fire into the supplied action_group_id"
  }

  # Spot-check a fully-specified detection: category + operation_name.
  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["role-assignment-created"].criteria[0].category == "Administrative"
    error_message = "role-assignment-created should use the Administrative category"
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["role-assignment-created"].criteria[0].operation_name == "Microsoft.Authorization/roleAssignments/write"
    error_message = "role-assignment-created should target the roleAssignments/write operation"
  }

  # Detection names are prefixed with the default name_prefix.
  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["role-assignment-created"].name == "rhythmic-role-assignment-created"
    error_message = "detection name should be name_prefix + key"
  }

  # Alert rules are created in the supplied resource group and scoped to the
  # current subscription.
  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["role-assignment-created"].resource_group_name == "rhythmic-monitoring"
    error_message = "detections should live in the supplied resource group"
  }

  assert {
    condition     = contains(azurerm_monitor_activity_log_alert.detections["role-assignment-created"].scopes, "/subscriptions/00000000-0000-0000-0000-000000000000")
    error_message = "detections should be scoped to the current subscription"
  }

  # Activity-log alert rules are global.
  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["role-assignment-created"].location == "global"
    error_message = "activity-log alert rules should be global"
  }

  # Backup-failure routing is on by default and narrowed to Azure Backup.
  assert {
    condition     = length(azurerm_monitor_alert_processing_rule_action_group.backup_failure) == 1
    error_message = "backup-failure routing should be created by default"
  }

  assert {
    condition     = azurerm_monitor_alert_processing_rule_action_group.backup_failure[0].add_action_group_ids[0] == var.action_group_id
    error_message = "backup-failure routing should attach the supplied action_group_id"
  }

  assert {
    condition     = azurerm_monitor_alert_processing_rule_action_group.backup_failure[0].condition[0].monitor_service[0].values[0] == "Azure Backup"
    error_message = "backup-failure routing should filter on the Azure Backup monitor service"
  }

  assert {
    condition     = azurerm_monitor_alert_processing_rule_action_group.backup_failure[0].condition[0].monitor_service[0].operator == "Equals"
    error_message = "backup-failure routing should use the Equals operator on monitor_service"
  }

  # Defender posture is fully opt-in: nothing enabled by default.
  assert {
    condition     = length(azurerm_security_center_subscription_pricing.plans) == 0
    error_message = "no Defender pricing plans should be enabled by default"
  }

  assert {
    condition     = length(azurerm_security_center_contact.security) == 0
    error_message = "no security contact should be created by default"
  }
}
