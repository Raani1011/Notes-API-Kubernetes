resource "kubernetes_namespace" "env_namespace" {
  metadata {
    name = var.environment
  }
}
