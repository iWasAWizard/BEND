#!/bin/bash
# switch-model.sh - A script to configure BEND for a specific pre-defined model.

# This script's only job is to write the correct environment variables to the .env file
# based on a model key from models.yaml.
#
# It should be run AFTER you have downloaded the necessary models using:
# - ./scripts/download-hf-model.sh
# - ./scripts/download-gguf-model.sh

set -e
BEND_ROOT=$(git rev-parse --show-toplevel)
cd "$BEND_ROOT"

MODEL_KEY=$1
MODELS_FILE="models.yaml"
ENV_FILE=".env"

if [ -z "$MODEL_KEY" ]; then
  echo "Usage: $0 <model_key_from_models_yaml>"
  echo "Example: $0 llama3"
  exit 1
fi

# Function to update or add a key-value pair in the .env file
update_env() {
  local key=$1
  local value=$2
  # If the key exists, update it. Otherwise, add it.
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
  rm -f "${ENV_FILE}.bak"
}

# Ensure .env file exists
touch "$ENV_FILE"

# Check if the input is a known key in models.yaml
MODEL_ENTRY=$(yq ".models[] | select(.key == \"$MODEL_KEY\")" "$MODELS_FILE")

if [ -n "$MODEL_ENTRY" ]; then
  echo "✅ Found key '$MODEL_KEY' in $MODELS_FILE. Configuring from manifest."

  HF_MODEL_NAME=$(echo "$MODEL_ENTRY" | yq -r '.name')
  KOBOLDCPP_MODEL_NAME=$(echo "$MODEL_ENTRY" | yq -r '.koboldcpp_model_name // ""')
  CONTEXT_SIZE=$(echo "$MODEL_ENTRY" | yq -r '.default_max_context_length // 8192')

  update_env "MODEL_NAME" "$HF_MODEL_NAME"
  update_env "KOBOLDCPP_MODEL_NAME" "$KOBOLDCPP_MODEL_NAME"
  update_env "MODEL_CONTEXT_SIZE" "$CONTEXT_SIZE"
  update_env "OLLM_API_BASE_URL" "http://vllm:8000/v1"

  echo "----------------------------------------"
  echo "Model configured successfully:"
  echo "  vLLM Model:       $HF_MODEL_NAME"
  echo "  KoboldCPP Model:  $KOBOLDCPP_MODEL_NAME"
  echo "  Context Size:     $CONTEXT_SIZE"
  echo "----------------------------------------"
else
  echo "❌ Error: Key '$MODEL_KEY' not found in $MODELS_FILE."
  echo "Please use a valid key from the manifest or add a new entry."
  exit 1
fi