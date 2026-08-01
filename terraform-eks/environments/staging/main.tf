module "eks" {
  source               = "../../modules/eks"
  environment          = "staging"
  replica_count        = 2
  postgres_password    = var.postgres_password
}


variable "postgres_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
}
