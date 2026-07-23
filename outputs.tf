output "activity_log_alert_ids" {
  description = "Map of detection key to the resource ID of its activity-log alert rule."
  value       = { for k, r in azurerm_monitor_activity_log_alert.detections : k => r.id }
}

output "enabled_defender_plans" {
  description = "Sorted list of Defender for Cloud resource_types this module enabled a pricing plan for (empty when defender_plans is unset)."
  value       = sort(keys(azurerm_security_center_subscription_pricing.plans))
}
