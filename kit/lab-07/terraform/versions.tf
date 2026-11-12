# Versions vérifiées le 5 novembre 2026 (voir 17_Videos_Jours/sources.md).
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.12"
    }
  }

  # Configuration partielle : les valeurs viennent de « backend.hcl » ou des
  # variables du pipeline (terraform init -backend-config=...).
  # Authentification par OpenID Connect (aucun secret stocké) : ARM_USE_OIDC=true.
  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  # Depuis azurerm 5.0, aucun fournisseur de ressources n'est enregistré
  # automatiquement : on n'enregistre que ceux dont la boutique a besoin.
  resource_providers_to_register = [
    "Microsoft.Web",
    "Microsoft.Consumption",
  ]

  features {}
  # subscription_id, tenant_id, client_id : variables d'environnement ARM_*.
}
