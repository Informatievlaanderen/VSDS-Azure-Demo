variable "ldes" {
  type = string
  default = "https://private-api.gipod.beta-vlaanderen.be/api/v1/ldes/mobility-hindrances"
}

variable "user_principal_id" {
  type = string
  default = "aee5b661-6d8c-4996-bcc2-53d4f1401de4" #WOUTER
#  default = "fa70612d-08f7-444e-9a69-5b3dba8e1820" #JAN
}

variable "location" {
  type = string
  default = "westeurope"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}