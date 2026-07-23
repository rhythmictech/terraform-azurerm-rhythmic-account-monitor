# basic

Minimal invocation of `terraform-azurerm-rhythmic-account-monitor`: the curated
control-plane detections plus the Azure Backup job-failure routing rule, all
firing into an existing account-alerts Action Group, with one Defender for Cloud
plan enabled to show the opt-in map shape.

In a real deployment the `action_group_id` and `resource_group_name` come from
the `terraform-azurerm-rhythmic-core` module's outputs.

```bash
terraform init
terraform plan -var 'subscription_id=00000000-0000-0000-0000-000000000000'
```
