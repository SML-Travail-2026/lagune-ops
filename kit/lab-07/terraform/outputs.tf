output "resource_group_name" {
  description = "Groupe de ressources de la boutique."
  value       = azurerm_resource_group.lagune.name
}

output "web_app_name" {
  description = "Nom de l'application App Service (utilisé par le pipeline pour le scan ZAP)."
  value       = azurerm_linux_web_app.boutique.name
}

output "default_hostname" {
  description = "Nom par défaut de l'application : cible du CNAME du sous-domaine."
  value       = azurerm_linux_web_app.boutique.default_hostname
}

output "custom_domain_verification_id" {
  description = "Valeur de l'enregistrement TXT asuid.<sous-domaine> (preuve de propriété du domaine, pas un secret)."
  value       = azurerm_linux_web_app.boutique.custom_domain_verification_id
  # Marquée sensible par prudence (masquée dans les journaux) ; à lire avec terraform output -raw.
  sensitive = true
}

output "boutique_url" {
  description = "Adresse de la boutique."
  value       = var.enable_custom_domain ? "https://${var.custom_hostname}" : "https://${azurerm_linux_web_app.boutique.default_hostname}"
}
