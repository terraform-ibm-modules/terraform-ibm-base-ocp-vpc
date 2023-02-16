#!/bin/bash

set -e

function run_checks() {

  LAST_ATTEMPT=$1
  NAMESPACE=calico-system

  # Get list of calico-node pods (There will be 1 pod per worker node)
  PODS=()
  while IFS='' read -r LINE; do PODS+=("$LINE"); done < <(oc get pods -n "${NAMESPACE}" | grep calico-node | cut -f1 -d ' ')

  # Iterate through pods to check health
  HEALTHY=true
  for pod in "${PODS[@]}"; do
    COMMAND="oc logs ${pod} -n ${NAMESPACE} --tail=0"
    # If it is the last attempt then print the output
    if [ "${LAST_ATTEMPT}" == true ]; then
      NODE=$(oc get pod "$pod" -n "${NAMESPACE}" -o=jsonpath='{.spec.nodeName}')
      echo "Checking node: $NODE"
      if ! ${COMMAND}; then
        HEALTHY=false
      else
        echo "OK"
      fi
    # Otherwise redirect output to /dev/null
    else
      if ! ${COMMAND} &> /dev/null; then
        HEALTHY=false
      fi
    fi
  done

  if [ "$HEALTHY" == "false" ]; then
    return 1
  else
    return 0
  fi

}

COUNTER=0
RETRY_COUNT=40
RETRY_WAIT_TIME=60

echo "Running script to ensure kube master can communicate with all worker nodes.."

while [ ${COUNTER} -le ${RETRY_COUNT} ]; do

  # Determine if it is last attempt
  LAST_ATTEMPT=false
  if [ "${COUNTER}" -eq ${RETRY_COUNT} ]; then
    LAST_ATTEMPT=true
  fi

  ((COUNTER=COUNTER+1))
  if ! run_checks ${LAST_ATTEMPT}; then
    if [ "${COUNTER}" -gt ${RETRY_COUNT} ]; then
      echo "Maximum attempts reached, giving up."
      echo
      echo "Found kube master is unable to communicate with one or more of its workers."
      echo "Please create a support issue with IBM Cloud and include the error message."
      exit 1
    else
      echo "Retrying in ${RETRY_WAIT_TIME}s. (Retry attempt ${COUNTER} / ${RETRY_COUNT})"
      sleep ${RETRY_WAIT_TIME}
    fi
  else
    break
  fi
done

echo "Success! Master can communicate with all worker nodes."
