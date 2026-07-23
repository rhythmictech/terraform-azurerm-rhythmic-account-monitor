mock_provider "azurerm" {
  source = "./tests/setup"
}

# Supplying defender_plans enables one pricing resource per key with the right
# tier/subplan, and a non-null security_contact_email creates one contact.
run "plans_and_contact" {
  command = plan

  variables {
    action_group_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rhythmic-monitoring/providers/microsoft.insights/actionGroups/rhythmic-accountalerts"
    resource_group_name = "rhythmic-monitoring"

    defender_plans = {
      VirtualMachines = {}
      StorageAccounts = {
        subplan = "PerStorageAccount"
      }
    }

    security_contact_email = "soc@example.com"
  }

  assert {
    condition     = length(azurerm_security_center_subscription_pricing.plans) == 2
    error_message = "two defender_plans entries should enable two pricing resources"
  }

  assert {
    condition     = azurerm_security_center_subscription_pricing.plans["VirtualMachines"].resource_type == "VirtualMachines"
    error_message = "pricing resource_type should come from the map key"
  }

  assert {
    condition     = azurerm_security_center_subscription_pricing.plans["VirtualMachines"].tier == "Standard"
    error_message = "tier should default to Standard"
  }

  assert {
    condition     = azurerm_security_center_subscription_pricing.plans["StorageAccounts"].subplan == "PerStorageAccount"
    error_message = "subplan should pass through when set"
  }

  assert {
    condition     = length(azurerm_security_center_contact.security) == 1
    error_message = "a non-null security_contact_email should create one contact"
  }

  assert {
    condition     = azurerm_security_center_contact.security[0].email == "soc@example.com"
    error_message = "the contact should use the supplied email"
  }

  assert {
    condition     = azurerm_security_center_contact.security[0].alert_notifications == true
    error_message = "the contact should enable alert notifications by default"
  }
}
