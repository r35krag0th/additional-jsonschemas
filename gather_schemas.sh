#!/usr/bin/env bash

set -euo pipefail

base_directory=$(realpath $(dirname $0))

echo "";
echo -e "\033[32m==>\033[0m Gathering Schemas";

find $base_directory/schemas/ \
  -name '*.json' \
  -exclude schemas/kubernets \
  -exec cp -v {} $base_directory/public/ \;

cp -pr $base_directory/schemas/kubernetes $base_directory/kubernetes;

echo "";
echo -e "\033[36m===\033[0m Done";
echo "";
