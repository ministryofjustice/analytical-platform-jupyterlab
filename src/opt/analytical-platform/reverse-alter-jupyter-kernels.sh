#!/usr/bin/env bash

echo "reverse-alter-jupyter-kernels.sh"

TARGET_DIR="/home/jovyan/.local/share/jupyter/kernels"
SOURCE_DIR="/home/analyticalplatform/.local"
BASE_DIR="$TARGET_DIR"

# Copy .local directory back to /home/jovyan/.local
if [ -d "$SOURCE_DIR" ]; then
  echo "Copying $SOURCE_DIR to $TARGET_DIR..."
  cp -r "$SOURCE_DIR"/* "$TARGET_DIR"
  echo "Copy completed."
else
  echo "Source directory $SOURCE_DIR does not exist."
  exit 1
fi

# Find all kernel.json files and replace 'analyticalplatform' with 'jovyan'
if [ -d "$BASE_DIR" ]; then
  echo "Searching for kernel.json files in $BASE_DIR..."
  if find "$BASE_DIR" -name "kernel.json" | grep -q 'kernel.json'; then
    echo "Found kernel.json files. Editing..."
    find "$BASE_DIR" -name "kernel.json" -exec sed -i '' 's/analyticalplatform/jovyan/g' {} +
    echo "Editing completed."
  else
    echo "No kernel.json files found in $BASE_DIR."
  fi
else
  echo "Base directory $BASE_DIR does not exist."
  exit 1
fi
