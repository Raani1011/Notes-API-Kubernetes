module "eks" {
  source               = "git::https://github.com/Raani1011/Notes-API-Kubernetes.git//terraform-eks/modules/eks?ref=eks-module-v1.0.0"
  environment          = "staging"
  replica_count        = 2
  postgres_password    = var.postgres_password
}


variable "postgres_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
}
# CI/CD test comment
