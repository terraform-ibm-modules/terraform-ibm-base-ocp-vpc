##############################################################################
# Terraform providers
##############################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = 60
}

provider "ibm" {
  alias            = "access_tags"
  ibmcloud_api_key = var.ibmcloud_access_tags_api_key != null ? var.ibmcloud_access_tags_api_key : var.ibmcloud_api_key
  region           = var.region
}

##############################################################################
