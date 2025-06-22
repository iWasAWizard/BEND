#!/bin/bash
# bootstrap.sh - Environment prep for BEND

set -e

echo "[+] Checking for yq..."
if ! command -v yq &> /dev/null; then
  echo "[!] 'yq' not found. Installing..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo snap install yq
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install yq
  else
    echo "[-] Unsupported OS. Please install 'yq' manually: https://github.com/mikefarah/yq"
    exit 1
  fi
else
  echo "[✓] yq is installed."
fi

echo "[+] Bootstrapping complete."

