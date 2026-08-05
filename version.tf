terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # Use "greater than or equal to" range in modules
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 2.3.0, < 3.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">=2.3.5, <3.0.0"
    }
  }
}
