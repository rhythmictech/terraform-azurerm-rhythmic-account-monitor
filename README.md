# terraform-azurerm-rhythmic-account-monitor

Account-level security, health, and governance monitoring for a Rhythmic-managed
Azure subscription. The module emits well-typed control-plane events into a
single shared Action Group and lets the downstream monitoring backend classify
and fan them out; it produces events, it does not own the routing rules.

Called once per subscription (with an aliased provider), it creates:

- **Control-plane detections**: one `azurerm_monitor_activity_log_alert` per
  entry in a curated catalog (role-assignment changes, policy-assignment
  changes, Defender plan changes, Recovery Services vault deletion, backup
  policy changes, and Azure Policy non-compliance). Each rule fires into the
  shared account-alerts Action Group passed in as `action_group_id`.
- **Backup job-failure routing**: an `azurerm_monitor_alert_processing_rule_action_group`
  that attaches the same Action Group to Azure Backup's built-in job-failure
  alerts. Recovery Services vaults raise these alerts natively, but without a
  processing rule they reach no Action Group. Enabled by default; toggle with
  `enable_backup_failure_routing`.
- **Microsoft Defender for Cloud posture (opt-in)**: zero or more
  `azurerm_security_center_subscription_pricing` plans (empty by default, since
  enabling paid plans is a deliberate per-subscription cost decision) and an
  optional `azurerm_security_center_contact`.

The subscription scope is derived from the invoking credential
(`data.azurerm_subscription`), so the caller never passes a subscription id.
The module requires only the `azurerm` provider.

## Usage

```hcl
module "account_monitor" {
  source  = "rhythmictech/rhythmic-account-monitor/azurerm"
  version = "~> 0.1"

  # Typically the rhythmic-core module's outputs.
  action_group_id     = module.core.account_action_group_id
  resource_group_name = module.core.resource_group_name

  # Opt-in Defender for Cloud plans (empty by default).
  defender_plans = {
    VirtualMachines = { tier = "Standard" }
    StorageAccounts = { tier = "Standard", subplan = "PerStorageAccount" }
    SqlServers      = { tier = "Standard" }
    AppServices     = { tier = "Standard" }
  }

  # Optional Defender for Cloud security contact.
  security_contact_email = "soc@example.com"

  tags = {
    managed_by = "terraform"
  }
}
```

Until this module is published to the Terraform Registry, pin it by git ref:

```hcl
module "account_monitor" {
  source = "git::https://github.com/rhythmictech/terraform-azurerm-rhythmic-account-monitor.git?ref=v0.1.0"
  # ...
}
```

See [`examples/basic`](examples/basic) for a runnable configuration.

## Design notes

- **One rule per operation.** Azure activity-log alert criteria are singular:
  a rule filters on a single `operation_name`. The catalog is therefore modeled
  as one operation per map entry. Override the whole `activity_log_detections`
  map to replace the curated set, or add entries for subscription-specific
  operations. A `null` `operation_name` produces a category-wide rule (used for
  the Policy non-compliance entry).
- **Detection transport.** Detections route to the shared Action Group only; the
  PagerDuty and Slack fan-out stays downstream in the monitoring backend, so
  this module produces events rather than routing rules.
- **Security contact name.** `security_contact_name` defaults to the canonical
  single-contact name. Azure validates the accepted value at apply time.
- **Operation names.** The catalog's default `operation_name` strings are
  standard Azure control-plane operations; the provider confirms them against
  the subscription at apply time. Adjust the map if a subscription exposes a
  different operation surface.

## Coverage notes

- **Vault-lock / immutability changes.** Azure Recovery Services immutability
  changes ride the broad `vaults/write` operation, which is too noisy to alert
  on directly, so there is no dedicated rule for them. This is a known coverage
  gap versus the corresponding backup-lock detection on other clouds.
- **Directory (Entra ID) audit and sign-in log routing** is out of scope here.
  It is handled by the Datadog integration module's `modules/activity-log`
  submodule, which routes Entra diagnostics behind its own feature flag. Enable
  it there, not in this module.
- **Service Health / Resource Health** alerting is intentionally omitted to
  avoid double-routing; it is owned by the health monitor set.
- **Service-quota monitoring** is a candidate follow-up (Azure-native quota
  alerts or a scheduled Function). It is not implemented in this version.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_tags"></a> [tags](#module\_tags) | rhythmictech/tags/terraform | ~> 1.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_monitor_activity_log_alert.detections](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_alert_processing_rule_action_group.backup_failure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_processing_rule_action_group) | resource |
| [azurerm_security_center_contact.security](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_contact) | resource |
| [azurerm_security_center_subscription_pricing.plans](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_subscription_pricing) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_action_group_id"></a> [action\_group\_id](#input\_action\_group\_id) | Resource ID of the shared account-alerts Action Group every detection fires into (typically the rhythmic-core module's account\_action\_group\_id output). | `string` | n/a | yes |
| <a name="input_activity_log_detections"></a> [activity\_log\_detections](#input\_activity\_log\_detections) | Control-plane detections rendered as activity-log alert rules wired to the Action Group. Keys are rule name suffixes. Override the whole map to replace the curated catalog. category is required; operation\_name narrows to a single control-plane operation (leave null for a category-wide rule); level optionally filters by severity. | <pre>map(object({<br/>    category       = string<br/>    operation_name = optional(string)<br/>    level          = optional(string)<br/>    description    = string<br/>  }))</pre> | <pre>{<br/>  "backup-policy-changed": {<br/>    "category": "Administrative",<br/>    "description": "A Recovery Services backup policy was created or modified.",<br/>    "operation_name": "Microsoft.RecoveryServices/vaults/backupPolicies/write"<br/>  },<br/>  "defender-plan-changed": {<br/>    "category": "Administrative",<br/>    "description": "A Microsoft Defender for Cloud plan tier was changed (guards against silent downgrades).",<br/>    "operation_name": "Microsoft.Security/pricings/write"<br/>  },<br/>  "policy-assignment-created": {<br/>    "category": "Administrative",<br/>    "description": "A policy assignment was created or updated.",<br/>    "operation_name": "Microsoft.Authorization/policyAssignments/write"<br/>  },<br/>  "policy-assignment-deleted": {<br/>    "category": "Administrative",<br/>    "description": "A policy assignment was deleted.",<br/>    "operation_name": "Microsoft.Authorization/policyAssignments/delete"<br/>  },<br/>  "policy-noncompliance": {<br/>    "category": "Policy",<br/>    "description": "Azure Policy reported a compliance state change.",<br/>    "level": "Warning",<br/>    "operation_name": null<br/>  },<br/>  "recovery-vault-deleted": {<br/>    "category": "Administrative",<br/>    "description": "A Recovery Services vault was deleted.",<br/>    "operation_name": "Microsoft.RecoveryServices/vaults/delete"<br/>  },<br/>  "role-assignment-created": {<br/>    "category": "Administrative",<br/>    "description": "A role assignment was created (privilege grant).",<br/>    "operation_name": "Microsoft.Authorization/roleAssignments/write"<br/>  },<br/>  "role-assignment-deleted": {<br/>    "category": "Administrative",<br/>    "description": "A role assignment was deleted (privilege revocation).",<br/>    "operation_name": "Microsoft.Authorization/roleAssignments/delete"<br/>  }<br/>}</pre> | no |
| <a name="input_defender_plans"></a> [defender\_plans](#input\_defender\_plans) | Microsoft Defender for Cloud plans to enable on the subscription, keyed by resource\_type (e.g. VirtualMachines, AppServices, SqlServers, StorageAccounts). Empty by default: enabling paid plans is a deliberate per-client cost decision. | <pre>map(object({<br/>    tier    = optional(string, "Standard")<br/>    subplan = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_backup_failure_routing"></a> [enable\_backup\_failure\_routing](#input\_enable\_backup\_failure\_routing) | Create a subscription-scope alert processing rule that attaches the Action Group to Azure Backup's built-in job-failure alerts (Recovery Services vaults emit these natively; without a processing rule they route nowhere). | `bool` | `true` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for all resource names created by this module. | `string` | `"rhythmic-"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the (existing) resource group the activity-log alert rules are created in (typically the rhythmic-core module's resource\_group\_name output). | `string` | n/a | yes |
| <a name="input_security_contact_alert_notifications"></a> [security\_contact\_alert\_notifications](#input\_security\_contact\_alert\_notifications) | Whether the security contact receives email notifications for alerts. | `bool` | `true` | no |
| <a name="input_security_contact_alerts_to_admins"></a> [security\_contact\_alerts\_to\_admins](#input\_security\_contact\_alerts\_to\_admins) | Whether subscription administrators also receive the security contact's alert notifications. | `bool` | `true` | no |
| <a name="input_security_contact_email"></a> [security\_contact\_email](#input\_security\_contact\_email) | Email for the Defender for Cloud security contact. null skips creating the contact. | `string` | `null` | no |
| <a name="input_security_contact_name"></a> [security\_contact\_name](#input\_security\_contact\_name) | Name of the Defender for Cloud security contact resource. Azure validates the accepted value at apply time; the default matches the canonical single-contact name. | `string` | `"default1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | User-defined tags merged onto all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_activity_log_alert_ids"></a> [activity\_log\_alert\_ids](#output\_activity\_log\_alert\_ids) | Map of detection key to the resource ID of its activity-log alert rule. |
| <a name="output_enabled_defender_plans"></a> [enabled\_defender\_plans](#output\_enabled\_defender\_plans) | Sorted list of Defender for Cloud resource\_types this module enabled a pricing plan for (empty when defender\_plans is unset). |
<!-- END_TF_DOCS -->
