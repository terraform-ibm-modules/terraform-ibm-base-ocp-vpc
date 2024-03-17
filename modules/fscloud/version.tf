##############################################################################
# Terraform Version
##############################################################################
terraform {
  required_version = ">= 1.3.0, < 1.7.0"
  required_providers {
    # The below tflint-ignores are required because although the below providers are not directly required by this module,
    # they are required by consuming modules, and if not set here, the top level module calling this module will not be
    # able to set alternative alias for the providers.
    # See https://github.ibm.com/GoldenEye/issues/issues/2390 for full details

    # tflint-ignore: terraform_unused_required_providers
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.63.0, < 2.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1, < 4.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1, < 1.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1, < 3.0.0"
    }
  }
}
