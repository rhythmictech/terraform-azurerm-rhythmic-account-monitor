terraform {
  # >= 1.9 is REQUIRED: input-variable `validation {}` blocks reference the
  # variable's own value (and could reference other variables), and
  # `terraform test` uses `mock_provider` (>= 1.7) for the plan-only suite.
  required_version = ">= 1.9"

  required_providers {
    # azurerm ONLY. This module creates activity-log alert rules, an alert
    # processing rule, and optional Defender for Cloud pricing/contact resources;
    # the Action Group it fires into is an input id, so no datadog/azuread
    # provider is needed here.
    #
    # v4 is the current major (subscription_id is mandatory in the provider
    # block on v4 -> the example sets it). Do not leave >= 3.x, which silently
    # resolves to v4 with breaking changes unguarded.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
