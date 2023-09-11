terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}