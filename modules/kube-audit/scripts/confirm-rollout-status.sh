#!/bin/bash

set -e

# The binaries downloaded by the install-binaries script are located in the /tmp directory.
export PATH=$PATH:"/tmp"

deployment=$1
namespace=$2

kubectl rollout status deploy "${deployment}" -n "${namespace}" --timeout 30m
