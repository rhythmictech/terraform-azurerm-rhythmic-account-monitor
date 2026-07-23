locals {
  # Applied to every taggable resource. module.tags.tags_no_name yields the
  # standardized Rhythmic tag set (team, service, terraform_managed,
  # terraform_workspace) merged with user var.tags, excluding the Name key
  # (mirrors the sibling core module).
  tags = module.tags.tags_no_name

  # Subscription scope every detection and the backup-failure processing rule
  # are attached to. Derived from the invoking credential's subscription, so the
  # caller never passes a subscription id (mirrors the AWS module reading
  # data.aws_caller_identity).
  subscription_id = data.azurerm_subscription.current.id

  # Activity-log alert rules are global in ARM regardless of where the alerted
  # resources live, so this is fixed rather than a caller input.
  alert_location = "global"
}
