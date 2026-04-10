#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 SOURCE TARGET" >&2
  exit 1
fi

source_path=$1
target_path=$2

if [[ ! -e "$source_path" ]]; then
  echo "Source does not exist: $source_path" >&2
  exit 1
fi

if [[ -L "$target_path" ]]; then
  current_target=$(readlink "$target_path")

  if [[ "$current_target" == "$source_path" ]]; then
    echo "Symlink already exists: $target_path -> $source_path"
    exit 0
  fi

  echo "Target is already a symlink to a different path: $target_path -> $current_target" >&2
  exit 1
fi

if [[ -e "$target_path" ]]; then
  echo "Target already exists and is not a symlink: $target_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$target_path")"
ln -s "$source_path" "$target_path"
echo "Created symlink: $target_path -> $source_path"
