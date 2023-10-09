terraform {
  required_version = ">= 1.3.0, <1.6.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.56.1"
    }
    # The kubernetes provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    # The helm provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
    # The logdna provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    logdna = {
      source  = "logdna/logdna"
      version = ">= 1.14.2"
    }
  }
}

##############################################################################
