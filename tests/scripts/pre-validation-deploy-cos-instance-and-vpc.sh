#!/bin/bash

############################################################################################################
## This script is used by the catalog pipeline to deploy the VPC instance
## which are the prerequisites for the fully-configurable OCP VPC Cluster.
############################################################################################################

set -e

DA_DIR="solutions/fully-configurable"
TERRAFORM_SOURCE_DIR="tests/existing-resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning pre-requisite VPC instance .."
  terraform init || exit 1

  # $VALIDATION_APIKEY is available in the catalog runtime
  {
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "prefix=\"ocp-$(openssl rand -hex 2)\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  existing_resource_group_name="existing_resource_group_name"
  existing_resource_group_value=$(terraform output -state=terraform.tfstate -raw resource_group_name)
  existing_vpc_crn_name="existing_vpc_crn"
  existing_vpc_crn_value=$(terraform output -state=terraform.tfstate -raw vpc_crn)

  echo "Appending '${existing_resource_group_name}' and '${existing_vpc_crn_name}' input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg existing_resource_group_name "${existing_resource_group_name}" \
        --arg existing_resource_group_value "${existing_resource_group_value}" \
        --arg existing_vpc_crn_name "${existing_vpc_crn_name}" \
        --arg existing_vpc_crn_value "${existing_vpc_crn_value}" \
        '. + {($existing_resource_group_name): $existing_resource_group_value,($existing_vpc_crn_name): $existing_vpc_crn_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation completed successfully."
)
