#!/bin/bash

set -e

export PATH=$PATH:"/tmp"

deployment=$1
namespace=$2

kubectl rollout status deploy "${deployment}" -n "${namespace}" --timeout 30m
