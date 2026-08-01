resource "kubernetes_deployment" "notes_api" {
  metadata {
    name      = "notes-api"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        app = "notes-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "notes-api"
        }
      }

      spec {
        container {
          name  = "notes-api"
          image = "rania2609/notes-api:latest"

          port {
            container_port = 5000
          }

          env {
            name  = "APP_ENV"
            value = var.environment
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "DATABASE_URL"
            value = "postgresql://postgres:$(POSTGRES_PASSWORD)@postgres-service:5432/notesdb"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "250m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "notes_api_service" {
  metadata {
    name      = "notes-api-service"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      app = "notes-api"
    }

    port {
      port        = 5000
      target_port = 5000
    }
  }
}
