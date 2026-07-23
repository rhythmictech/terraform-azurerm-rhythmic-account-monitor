mock_provider "azurerm" {
  source = "./tests/setup"
}

# Every detection must carry a non-empty category (activity-log alert criteria
# require one). An empty category must trip the variable validation.
run "empty_category_rejected" {
  command = plan

  variables {
    action_group_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rhythmic-monitoring/providers/microsoft.insights/actionGroups/rhythmic-accountalerts"
    resource_group_name = "rhythmic-monitoring"

    activity_log_detections = {
      bad = {
        category    = ""
        description = "missing category"
      }
    }
  }

  expect_failures = [
    var.activity_log_detections,
  ]
}

# A non-empty category passes validation.
run "valid_category_ok" {
  command = plan

  variables {
    action_group_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rhythmic-monitoring/providers/microsoft.insights/actionGroups/rhythmic-accountalerts"
    resource_group_name = "rhythmic-monitoring"

    activity_log_detections = {
      good = {
        category    = "Administrative"
        description = "a valid detection"
      }
    }
  }

  assert {
    condition     = length(azurerm_monitor_activity_log_alert.detections) == 1
    error_message = "a valid single-entry catalog should render one rule"
  }
}
