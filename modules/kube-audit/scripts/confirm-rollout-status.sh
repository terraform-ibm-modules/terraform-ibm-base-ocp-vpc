#!/bin/bash

set -e

deployment=$1
namespace=$2

kubectl rollout status deploy "${deployment}" -n "${namespace}" --timeout 30m
