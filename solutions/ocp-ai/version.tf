terraform {
  required_version = ">= 1.3.0"

  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.70.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
