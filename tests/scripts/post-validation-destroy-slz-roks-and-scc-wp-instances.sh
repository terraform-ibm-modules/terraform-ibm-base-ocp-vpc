#! /bin/bash

########################################################################################################################
## This script is used by the catalog pipeline to destroy the COS instance and VPC, which was provisioned as a            ##
## prerequisite for the fully-configurable ocp vpc cluster that is published to the catalog                                                ##
########################################################################################################################

set -e

TERRAFORM_SOURCE_DIR="tests/resources/existing-resources"
TF_VARS_FILE="terraform.tfvars"

(
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Destroying prerequisite COS instance and VPC .."
  terraform destroy -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  echo "Post-validation completed successfully"
)
