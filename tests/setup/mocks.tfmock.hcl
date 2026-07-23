# Shared mock defaults for `terraform test`. Referenced from every *.tftest.hcl
# via `mock_provider "azurerm" { source = "./tests/setup" }`, so all plan-only
# tests run with no live Azure tenant. Only the resource and data source types
# this module touches are mocked.

# The subscription the module derives its alert/processing-rule scope from. A
# fixed all-zero guid keeps the scope deterministic across runs.
mock_data "azurerm_subscription" {
  defaults = {
    id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    display_name    = "mock-subscription"
    tenant_id       = "11111111-1111-1111-1111-111111111111"
    state           = "Enabled"
  }
}

mock_resource "azurerm_monitor_activity_log_alert" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/microsoft.insights/activityLogAlerts/mock"
  }
}

mock_resource "azurerm_monitor_alert_processing_rule_action_group" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.AlertsManagement/actionRules/mock"
  }
}

mock_resource "azurerm_security_center_subscription_pricing" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Security/pricings/mock"
  }
}

mock_resource "azurerm_security_center_contact" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Security/securityContacts/default1"
  }
}
