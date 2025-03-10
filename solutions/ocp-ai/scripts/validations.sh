#!/bin/bash
# Validation 1: To check the OCP Cluster version: OCP AI Addon Supports OpenShift cluster versions: >=4.16.0 <4.18.0
validate_ocp_version() {
  # The allowed versions range, for example: >=4.16.0 <4.18.0
  ALLOWED_VERSIONS=("4.16" "4.17" "4.18")

  # The OpenShift version passed as argument
  OCP_VERSION=$1

  # Extract the major and minor version from the input (e.g., 4.17.2 -> "4.17")
  OCP_MAJOR_MINOR=$(echo "$OCP_VERSION" | cut -d'.' -f1,2)

  # Check if the version is in the allowed range
  for version in "${ALLOWED_VERSIONS[@]}"; do
    if [ "$OCP_MAJOR_MINOR" == "$version" ]; then
      return 0
    fi
  done
  # If version is not in the allowed list, print the error message
  echo "OCPAI Addon Supports OpenShift cluster versions: >=4.16.0 <4.18.0"
  exit 1
}

# # Call the function with the provided version
validate_ocp_version "$1"
# # #######################################################
# Validation 2: The Cluster must have at least two worker nodes.
validate_worker_count() {
    local WORKER_COUNT=$2  # Capture the argument passed to the function

    # Check if the WORKER_COUNT is greater than or equal to 2
    if [ $WORKER_COUNT >= 2 ]; then
        return 0
    else
        echo "The Cluster must have at least two worker nodes."
        exit 1
    fi
}

# Call the function with the argument
validate_worker_count $2
# ##########################################################

 # Validation 3: All Worker nodes in the cluster must have minimum configuration as 8-core, 32GB memory.
validate_flavour() {
  # List of valid flavours

  FLAVOUR_LIST=("bx2.16x64" "bx2.32x128" "bx2.48x192" "bx2.8x32" "cx2.16x32" "cx2.32x64" "cx2.48x96" "gx3.16x80.l4" "gx3.24x120.l40s" "gx3.32x160.2l4" "gx3.48x240.2l40s" "gx3.64x320.4l4" "gx3d.160x1792.8h100" "gx3d.160x1792.8h200" "mx2.16x128" "mx2.128x1024" "mx2.16x128.2000gb" "mx2.32x256" "mx2.48x384" "mx2.64x512" "mx2.8x64" "ox2.128x1024" "ox2.16x128" "ox2.32x256" "ox2.64x512" "ox2.8x64" "ox2.96x768" )

  WORKER_FLAVOUR=$1
  WORKER_FLAVOUR=$(echo "$WORKER_FLAVOUR" | xargs)
  # Function to check if a flavour exists in the list
  for item in "${FLAVOUR_LIST[@]}"; do
    if [ "$WORKER_FLAVOUR" == "$item" ]; then
      return 0
    fi
  done

  # If the flavour is not found
  echo "All Worker nodes in the cluster must have a minimum configuration of 8-core, 32GB memory."
  exit 1
}

# Call the function with the provided argument
validate_flavour "$3"
# ############################################################

# Validation 4: Cluster must have access to the public internet.
# Validate_internet_access() {

#     RESPONSE=$(curl -I https://www.google.com 2>/dev/null)

#     # Check if the response contains "200 OK"
#     if echo "$RESPONSE" | grep -q "200 OK"; then
#         echo "Internet access is available."
#     else
#         echo "No internet access or unable to reach the server."
#         exit 1
#     fi
# }

# #Call the function
# Validate_internet_access

# ################################################################
# Validation 5: Check if already ocp-ai addon is installed in the cluster.
validate_openshift_ai() {
  INSTALLED_ADDONS=("$1")  # Expecting the list of addon names as space-separated values

  # Check if "openshift-ai" is in the list of installed addons
  for addon in "${INSTALLED_ADDONS[@]}"; do
    if [[ "$addon" == "openshift-ai" ]]; then
      echo "Openshift-ai is already installed in this cluster."
      exit 1  # Return 1 to indicate an error (validation failure)
    fi
  done

  return 0  # Return 0 to indicate success (validation passed)
}

# Call the function
validate_openshift_ai "$4"

# ############################################################

# Validatio 6 :Check operating system
validate_os() {
  # Allowed operating systems
  ALLOWED_OS=("RHEL_9_64" "REDHAT_8_64" "RHCOS")

  OS_NAME=$1

  # Check if the OS is in the allowed list
  for allowed_os in "${ALLOWED_OS[@]}"; do
    if [[ "$allowed_os" == "$OS_NAME" ]]; then
      return 0  # OS is valid
    fi
  done

  echo "RHEL 9 (RHEL_9_64), RHEL 8 (REDHAT_8_64), or Red Hat Enterprise Linux CoreOS (RHCOS) are the allowed OS values."
  exit 1  # OS is invalid
}

# Call the function with the worker node's OS
validate_os "$5"



####################################################
# Validation 7: GPU Worker node validation. If adding a GPU worker node, validation should be added for minimal configuration as validation3 and machine type for GPU Nodes.
validate_gpu_node() {
  # List of valid GPU flavors
  FLAVOUR_LIST=("gx3.16x80.l4" "gx3.24x120.l40s" "gx3.32x160.2l4" "gx3.48x240.2l40s" "gx3.64x320.4l4" "gx3d.160x1792.8h100" "gx3d.160x1792.8h200")

  NODE_FLAVOR="$1"
  POOL_NAME="$2"

  # If the pool name is "gpu", check if the flavor is valid
  if [ "$POOL_NAME" == "gpu" ]; then
    # Check if the flavor is in the list
    for flavor in "${FLAVOUR_LIST[@]}"; do
      if [[ "$flavor" == "$NODE_FLAVOR" ]]; then
        return 0  # Flavor is valid
      fi
    done
    # If the loop completes without finding the flavor, it's invalid
    echo "Invalid GPU node flavor '${NODE_FLAVOR}'."
    exit 1
  else
    return 0  # Pool name isn't "gpu", so no validation needed
  fi
}

# Call the function with the node flavor and pool name
validate_gpu_node "$3" "$6"

# # #########################################################

#Validation 8: Check the outbound traffic protection should be disabled, if any of the OpenShift Pipelines, Node Feature Discovery, or NVIDIA GPU operators are used with OCP AI addon.

# validate_outbound_traffic() {

#   OUTBOUND_TRAFFIC_PROTECTION_ENABLED="$1"  # true or false

#   # Check if outbound traffic protection is disabled
#   if [ "$OUTBOUND_TRAFFIC_PROTECTION_ENABLED" == "true" ]; then
#     echo "Outbound traffic protection is disabled."
#     return 0
#   else
#     echo "Outbound traffic protection must be disabled when OpenShift Pipelines, Node Feature Discovery, or NVIDIA GPU operators are used with OCP AI addon."
#     return 1
#   fi
# }


# # Call the function with the current protection status
# validate_outbound_traffic "$7"

# # #######################################################
