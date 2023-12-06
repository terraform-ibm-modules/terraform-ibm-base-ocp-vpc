##############################################################################
# Terraform Version
##############################################################################
terraform {
  required_version = ">= 1.3.0, < 1.6.0"
  required_providers {
    # The below tflint-ignores are required because although the below providers are not directly required by this module,
    # they are required by consuming modules, and if not set here, the top level module calling this module will not be
    # able to set alternative alias for the providers.
    # See https://github.ibm.com/GoldenEye/issues/issues/2390 for full details

    # tflint-ignore: terraform_unused_required_providers
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.60.0"
    }
  }
}
