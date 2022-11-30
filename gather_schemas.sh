#!/usr/bin/env bash

set -euo pipefail

base_directory=$(realpath $(dirname $0))

echo "";
echo -e "\033[32m==>\033[0m Gathering Schemas";

find $base_directory/schemas/ \
  -name '*.json' \
  -exec cp -v {} $base_directory/public/ \;

echo "";
echo -e "\033[36m===\033[0m Done";
echo "";
