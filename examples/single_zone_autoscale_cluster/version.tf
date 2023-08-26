terraform {
  required_version = ">=1.3.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.56.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
  }
}

##############################################################################
