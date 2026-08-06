variable "environment" {
  description = "Deployment environment name"
  type        = string
}


variable "replica_count" {
  description = "Number of Notes API replicas"
  type        = number
  default     = 2
}

variable "postgres_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
}
# Module v1.1.0: added clarifying comment
