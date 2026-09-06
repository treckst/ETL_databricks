variable "ENV" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

variable "LOCATION" {
  type        = string
  default     = "francecentral"
  description = "Geolocation for the resources"
}

variable "SUBSCRIPTION_ID" {
  type        = string
  description = "Azure Subscription ID"
}
