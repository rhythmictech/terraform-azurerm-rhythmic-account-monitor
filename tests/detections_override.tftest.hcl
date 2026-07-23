mock_provider "azurerm" {
  source = "./tests/setup"
}

# Overriding the whole catalog replaces the default set: a single custom entry
# yields exactly one alert rule named name_prefix + key, and disabling backup
# routing removes the processing rule entirely.
run "single_detection_no_backup_routing" {
  command = plan

  variables {
    action_group_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rhythmic-monitoring/providers/microsoft.insights/actionGroups/rhythmic-accountalerts"
    resource_group_name = "rhythmic-monitoring"
    name_prefix         = "custom-"

    enable_backup_failure_routing = false

    activity_log_detections = {
      keyvault-deleted = {
        category       = "Administrative"
        operation_name = "Microsoft.KeyVault/vaults/delete"
        description    = "A Key Vault was deleted."
      }
    }
  }

  assert {
    condition     = length(azurerm_monitor_activity_log_alert.detections) == 1
    error_message = "a one-entry override should render exactly one alert rule"
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["keyvault-deleted"].name == "custom-keyvault-deleted"
    error_message = "the override rule name should be name_prefix + key"
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.detections["keyvault-deleted"].criteria[0].operation_name == "Microsoft.KeyVault/vaults/delete"
    error_message = "the override rule should carry the supplied operation_name"
  }

  assert {
    condition     = length(azurerm_monitor_alert_processing_rule_action_group.backup_failure) == 0
    error_message = "disabling backup-failure routing should remove the processing rule"
  }
}
