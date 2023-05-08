#!/usr/bin/env bash

set -e

FLAVOR="cluster ls"

import_cmd=(ibmcloud ks)

import_cmd+=" --flavor \"${FLAVOR}\""

echo $import_cmd
