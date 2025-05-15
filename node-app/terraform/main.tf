terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "node-app"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "node-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "node-app"
        }
      }
      spec {
        container {
          image = "ghcr.io/4min4m/node-app:latest"
          name  = "node-app"
          port {
            container_port = 3000
          }
        }
        image_pull_secrets {
          name = "ghcr-secret"
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "node-app-service"
  }
  spec {
    selector = {
      app = "node-app"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}