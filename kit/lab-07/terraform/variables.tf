variable "prefix" {
  description = "Préfixe court des noms de ressources (lettres minuscules et chiffres, 3 à 12 caractères), par exemple « lagune01 »."
  type        = string
  default     = "lagune01"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.prefix))
    error_message = "Le préfixe doit contenir 3 à 12 lettres minuscules ou chiffres."
  }
}

variable "location" {
  description = "Région Azure."
  type        = string
  default     = "francecentral"
}

variable "room_ip_cidr" {
  description = "Adresse IP publique de la salle de formation, en notation CIDR (/32). Seule cette adresse peut ouvrir la boutique."
  type        = string
  # Plage de documentation (RFC 5737) : à remplacer par l'adresse réelle de la salle.
  default = "203.0.113.10/32"

  validation {
    condition     = can(cidrhost(var.room_ip_cidr, 0)) && endswith(var.room_ip_cidr, "/32")
    error_message = "Indiquez une seule adresse IPv4 au format a.b.c.d/32."
  }
}

variable "juice_shop_tag" {
  description = "Version épinglée de l'image officielle bkimminich/juice-shop (jamais « latest »)."
  type        = string
  default     = "v20.3.0"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.juice_shop_tag))
    error_message = "Utilisez une version précise, par exemple v20.3.0."
  }
}

variable "enable_custom_domain" {
  description = "Active le sous-domaine et le certificat géré. Mettre à true seulement quand les enregistrements DNS CNAME et TXT asuid existent."
  type        = bool
  default     = false
}

variable "custom_hostname" {
  description = "Sous-domaine de la boutique (un CNAME doit pointer vers le nom par défaut de l'application)."
  type        = string
  default     = "boutique.lagune.example"
}

variable "owner" {
  description = "Responsable des ressources (étiquette « proprietaire »)."
  type        = string
  default     = "equipe-lagune"
}

variable "expiration_date" {
  description = "Date de suppression prévue (étiquette « expiration »), format AAAA-MM-JJ."
  type        = string
  default     = "2026-12-31"
}

variable "budget_amount" {
  description = "Budget mensuel du groupe de ressources, dans la devise de l'abonnement."
  type        = number
  default     = 20
}

variable "budget_contact_email" {
  description = "Adresse qui reçoit les alertes de budget."
  type        = string
  default     = "formateur@lagune.example"
}
