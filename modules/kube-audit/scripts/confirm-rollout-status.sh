#!/bin/bash

set -e

# The binaries downloaded by the install-binaries script are located in the /tmp directory.
export PATH=$PATH:${1:-"/tmp"}

deployment=$2
namespace=$3

kubectl rollout status deploy "${deployment}" -n "${namespace}" --timeout 30m
