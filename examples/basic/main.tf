terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# azurerm v4 makes subscription_id mandatory in the provider block.
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Minimal invocation: the curated control-plane detections plus the backup
# job-failure routing rule, all firing into an existing account-alerts Action
# Group. One Defender plan is shown to illustrate the opt-in map shape. In a
# real deployment the action_group_id and resource_group_name come from the
# rhythmic-core module's outputs.
module "account_monitor" {
  source = "../../"

  action_group_id     = var.action_group_id
  resource_group_name = var.resource_group_name

  # Opt-in Defender for Cloud plan (empty by default). Enabling paid plans is a
  # deliberate per-subscription cost decision.
  defender_plans = {
    VirtualMachines = {
      tier = "Standard"
    }
  }

  tags = {
    managed_by = "terraform"
    module     = "terraform-azurerm-rhythmic-account-monitor"
  }
}
