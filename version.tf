terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # Use "greater than or equal to" range in modules
    ibm = {
      source                = "ibm-cloud/ibm"
      version               = ">= 1.49.0"
      configuration_aliases = [ibm.access_tags]
    }
    null = {
      version = ">= 3.2.1"
    }
  }
}
