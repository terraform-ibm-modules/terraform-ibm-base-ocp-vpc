terraform {
  required_version = ">= 1.9.0"

  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "2.5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.0"
    }
  }
}
