#!/usr/bin/env bash

# set -x
set -euo pipefail

base_directory=$(realpath $(dirname $0))

echo "";
echo -e "\033[32m==>\033[0m Gathering Non-Kubernetes Schemas";

find $base_directory/schemas \
  -type f \
  -not -path "$base_directory/schemas/kubernetes/*" \
  -and \
  -name '*.json' \
  -exec cp -v {} $base_directory/public/ \;

echo ""
echo -e "\033[32m==>\033[0m Gathering Kubernetes Schemas";
mkdir -p $base_directory/public/kubernetes
cp -pr $base_directory/schemas/kubernetes/v* $base_directory/public/kubernetes;

echo "";
echo -e "\033[36m===\033[0m Done";
echo "";
