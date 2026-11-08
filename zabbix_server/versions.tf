terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.13"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  # azurerm 5.x は既定でリソースプロバイダーを登録しないため、使用する分のみ明示する
  resource_providers_to_register = ["Microsoft.Compute", "Microsoft.Network"]
}
