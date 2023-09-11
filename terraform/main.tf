provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "mnk-3"
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "mnk-3"
}

data "kubectl_file_documents" "argocd-manifest" {
  content = file("manifest/argocd-install.yaml")
}

resource "kubernetes_namespace" "argocd-ns" {
  metadata {
    name = "argocd"
  }
}

# this is weird, it does some unexpected behaviors (even though that is the reason this approach works :) )
resource "kubectl_manifest" "argocd-install" {
  depends_on = [kubernetes_secret.argocd-password, kubernetes_service.argocd-server]

  for_each           = data.kubectl_file_documents.argocd-manifest.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubernetes_service" "argocd-server" {
  depends_on = [kubernetes_namespace.argocd-ns]

  metadata {
    labels = {
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/name"     = "argocd-server"
      "app.kubernetes.io/part-of"   = "argocd"
    }
    name = "argocd-server"
    namespace = "argocd"
  }

  spec {
    type     = "NodePort"
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
    port {
      name       = "http"
      port       = "80"
      protocol   = "TCP"
      target_port = "8080"
    }
    port {
      name       = "https"
      port       = "443"
      protocol   = "TCP"
      target_port = "8080"
    }

  }
}

resource "kubernetes_secret" "argocd-password" {
  depends_on = [kubernetes_namespace.argocd-ns]
  metadata {
    name      = "argocd-secret"
    namespace = "argocd"
  }

  data = {
    # to generate password: argocd account bcrypt --password <YOUR-PASSWORD-HERE>
    "admin.password" = "$2a$10$dG.DfrviDVUCCz7hHv.6/OmHutV2rCYh3r/icD8.XMTqyoQcKgyr6%"
  }
}
