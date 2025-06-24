#!/bin/bash
#
# download-all-models.sh
# Iterates through models.yaml and downloads all models for airgap packaging.
#

set -e

# --- Pre-flight Checks ---
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install it to use this script."
    exit 1
fi
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Please install it to use this script."
    exit 1
fi

# --- Main Logic ---
cd "$(dirname "$0")/.." # Move to BEND root directory

# Load .env file if it exists, to get HF_TOKEN
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Use HF_TOKEN from environment if it exists, otherwise prompt the user.
if [ -z "$HF_TOKEN" ]; then
    echo "Hugging Face token not found in .env file."
    read -p "Please enter your Hugging Face Read Token (hf_...): " HF_TOKEN
    if [ -z "$HF_TOKEN" ]; then
        echo "Error: Hugging Face token is required for downloading models."
        exit 1
    fi
fi

# Create models directory if it doesn't exist
mkdir -p models

# Extract all model URLs from the YAML file
MODEL_URLS=$(yq e '.models[].url' models.yaml)

echo "Found $(echo "$MODEL_URLS" | wc -l | xargs) models to download."

for url in $MODEL_URLS; do
    if [ -z "$url" ] || [ "$url" == "null" ]; then
        continue
    fi

    filename=$(basename "$url")
    dest_path="models/$filename"

    if [ -f "$dest_path" ]; then
        echo "✅ Model '$filename' already exists. Skipping."
    else
        echo "🔽 Downloading '$filename'..."
        # Use the token in the wget command
        wget --header="Authorization: Bearer $HF_TOKEN" -O "$dest_path" "$url"
    fi
done

echo "✅ All models downloaded successfully."