terraform {
  required_version = ">=1.9.0"

  # Using the latest provider version to ensure GPU support
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.79.2"
    }
  }
}
