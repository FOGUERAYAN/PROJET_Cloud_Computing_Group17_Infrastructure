# Remote state : le "carnet" de Terraform est rangé dans un Blob Azure.
# Ce compte de stockage est créé À LA MAIN une seule fois (voir docs/bootstrap-remote-state.md).
# Le verrouillage (locking) est automatique : Terraform pose un bail (lease) sur le blob pendant un apply.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cap90-tfstate"
    storage_account_name = "sttfstatecap90gd"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
