terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# L'ID d'abonnement n'est PAS écrit ici : chacun l'exporte dans son terminal
#   export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)      (Linux/Mac)
#   $env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)       (PowerShell)
provider "azurerm" {
  features {}
}
