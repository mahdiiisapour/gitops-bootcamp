variable "keycloak_url" {
  description = "Keycloak base URL"
  type        = string
}

variable "keycloak_client_id" {
  description = "Keycloak admin client ID"
  type        = string
  default     = "admin-cli"
}

variable "keycloak_username" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}
