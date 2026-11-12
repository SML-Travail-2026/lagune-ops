# Boutique de Lagune Services : OWASP Juice Shop sur Azure App Service (Linux).
# Trois conditions de sécurité : accès réservé à l'IP de la salle, durée de vie
# courte (étiquette « expiration » + pipeline destroy), cadre légal (README).

locals {
  tags = {
    projet        = "lagune-ops"
    formation     = "AZM-201"
    environnement = "formation"
    proprietaire  = var.owner
    expiration    = var.expiration_date
  }

  # Azure exige un début de budget au premier jour du mois en cours.
  budget_start_date = formatdate("YYYY-MM-01'T'00:00:00Z", plantimestamp())
}

resource "azurerm_resource_group" "lagune" {
  name     = "rg-${var.prefix}-boutique"
  location = var.location
  tags     = local.tags
}

resource "azurerm_service_plan" "lagune" {
  name                = "asp-${var.prefix}-boutique"
  resource_group_name = azurerm_resource_group.lagune.name
  location            = azurerm_resource_group.lagune.location
  os_type             = "Linux"
  # B1 (Basic) : le plus petit niveau qui accepte un domaine personnalisé
  # et le certificat géré gratuit.
  sku_name = "B1"
  tags     = local.tags
}

resource "azurerm_linux_web_app" "boutique" {
  name                = "app-${var.prefix}-boutique"
  resource_group_name = azurerm_resource_group.lagune.name
  location            = azurerm_service_plan.lagune.location
  service_plan_id     = azurerm_service_plan.lagune.id
  https_only          = true
  tags                = local.tags

  app_settings = {
    # Juice Shop écoute sur le port 3000.
    WEBSITES_PORT = "3000"
  }

  site_config {
    always_on           = true
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    http2_enabled       = true

    application_stack {
      docker_image_name   = "bkimminich/juice-shop:${var.juice_shop_tag}"
      docker_registry_url = "https://index.docker.io"
    }

    # Tout est refusé, sauf l'adresse IP de la salle.
    ip_restriction_default_action = "Deny"
    ip_restriction {
      name       = "salle-de-formation"
      action     = "Allow"
      priority   = 100
      ip_address = var.room_ip_cidr
    }

    # Même règle pour le site d'administration (SCM / Kudu).
    scm_ip_restriction_default_action = "Deny"
    scm_ip_restriction {
      name       = "salle-de-formation"
      action     = "Allow"
      priority   = 100
      ip_address = var.room_ip_cidr
    }
  }
}

# --- Sous-domaine + certificat géré (gratuit) -------------------------------
# Prérequis DNS, créés à la main chez l'hébergeur du domaine AVANT d'activer
# enable_custom_domain :
#   CNAME  boutique        -> <default_hostname> (sortie Terraform)
#   TXT    asuid.boutique  -> <custom_domain_verification_id> (sortie Terraform)

resource "azurerm_app_service_custom_hostname_binding" "boutique" {
  count               = var.enable_custom_domain ? 1 : 0
  hostname            = var.custom_hostname
  app_service_name    = azurerm_linux_web_app.boutique.name
  resource_group_name = azurerm_resource_group.lagune.name

  # La liaison SNI est gérée par azurerm_app_service_certificate_binding.
  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "boutique" {
  count                      = var.enable_custom_domain ? 1 : 0
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.boutique[0].id
  tags                       = local.tags
}

resource "azurerm_app_service_certificate_binding" "boutique" {
  count               = var.enable_custom_domain ? 1 : 0
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.boutique[0].id
  certificate_id      = azurerm_app_service_managed_certificate.boutique[0].id
  ssl_state           = "SniEnabled"
}

# --- Le coût d'abord : alerte de budget --------------------------------------
resource "azurerm_consumption_budget_resource_group" "lagune" {
  name              = "budget-${var.prefix}-boutique"
  resource_group_id = azurerm_resource_group.lagune.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  # La date est fixée à la création ; la changer recréerait le budget.
  lifecycle {
    ignore_changes = [time_period]
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = [var.budget_contact_email]
  }
}
