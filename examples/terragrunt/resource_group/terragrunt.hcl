terraform {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.4.0"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  resource_group_name = "abcd-resource-group"
}
