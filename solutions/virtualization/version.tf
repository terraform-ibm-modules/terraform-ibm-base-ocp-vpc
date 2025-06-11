
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.75.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
