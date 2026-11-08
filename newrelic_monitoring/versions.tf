terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.13"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.101"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  # azurerm 5.x は既定でリソースプロバイダーを登録しないため、使用する分のみ明示する
  resource_providers_to_register = ["Microsoft.Compute", "Microsoft.Network"]
}

provider "newrelic" {
  account_id = var.newrelic_account_id
  api_key    = var.newrelic_api_key
  region     = var.newrelic_region
}
