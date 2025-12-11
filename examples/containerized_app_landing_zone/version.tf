terraform {
  required_version = ">=1.9.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.78.2, < 2.0.0"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 2.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0, <4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
  }
}
