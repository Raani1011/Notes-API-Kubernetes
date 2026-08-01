module "eks" {
  source             = "../../modules/eks"
  environment        = "production"
  replica_count      = 4
  postgres_password  = var.postgres_password
}


variable "postgres_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
}
