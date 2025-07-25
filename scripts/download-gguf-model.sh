#!/bin/bash
# scripts/download-gguf-model.sh
# Downloads a single GGUF model file based on a key from models.yaml.
# This is primarily for use with the KoboldCPP service.

set -e
BEND_ROOT=$(git rev-parse --show-toplevel)
cd "$BEND_ROOT"

MODEL_KEY=$1
MODELS_FILE="models.yaml"
MODELS_DIR="models"

if [ -z "$MODEL_KEY" ]; then
  echo "Usage: $0 <model_key_from_models_yaml>"
  echo "Example: $0 llama3"
  exit 1
fi

# Ensure the models directory exists
mkdir -p "$MODELS_DIR"

# Extract model info from YAML using yq
MODEL_URL=$(yq ".models[] | select(.key == \"$MODEL_KEY\") | .url" "$MODELS_FILE")
MODEL_FILENAME=$(yq ".models[] | select(.key == \"$MODEL_KEY\") | .koboldcpp_model_name" "$MODELS_FILE")

if [ -z "$MODEL_URL" ] || [ "$MODEL_URL" == "null" ]; then
  echo "Error: Model key '$MODEL_KEY' not found or has no URL in $MODELS_FILE."
  exit 1
fi

if [ -z "$MODEL_FILENAME" ] || [ "$MODEL_FILENAME" == "null" ]; then
    echo "Error: Model key '$MODEL_KEY' does not have a 'koboldcpp_model_name' defined in $MODELS_FILE."
    exit 1
fi

TARGET_PATH="$MODELS_DIR/$MODEL_FILENAME"

if [ -f "$TARGET_PATH" ]; then
  echo "Model file '$MODEL_FILENAME' already exists. Skipping download."
else
  echo "Downloading '$MODEL_FILENAME' from '$MODEL_URL'..."
  wget -O "$TARGET_PATH" "$MODEL_URL"
  echo "✅ Download complete."
fi