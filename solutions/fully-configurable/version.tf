terraform {
  required_version = ">=1.9.0"

  # Lock DA into an exact provider version - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.81.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}
