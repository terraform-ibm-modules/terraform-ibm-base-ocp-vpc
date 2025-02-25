#!/bin/bash

set -e

deployment=$1
namespace=$2

sleep 60

kubectl rollout status deploy "${deployment}" -n "${namespace}" --timeout 30m
