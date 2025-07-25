#!/bin/bash
# switch-model.sh - A smart script to configure BEND for a specific model.

# It can be used in two ways:
# 1. By KEY: ./scripts/switch-model.sh llama3
#    - Looks up the key 'llama3' in models.yaml.
#    - Configures both vLLM and KoboldCPP with the values from the manifest.
#    - TRIGGERS THE DOWNLOAD of the GGUF model if not present.
#
# 2. By Hugging Face REPO_ID: ./scripts/switch-model.sh "mistralai/Mistral-7B-Instruct-v0.2"
#    - Treats the argument as a repo ID.
#    - Configures vLLM to use this model directly.
#    - TRIGGERS THE DOWNLOAD of the full HF repository if not present.
#    - Disables KoboldCPP for this run (as the GGUF is unknown) and warns the user.

set -e
BEND_ROOT=$(git rev-parse --show-toplevel)
cd "$BEND_ROOT"

MODEL_KEY_OR_REPO_ID=$1
MODELS_FILE="models.yaml"
ENV_FILE=".env"

if [ -z "$MODEL_KEY_OR_REPO_ID" ]; then
  echo "Usage: $0 <model_key_from_models_yaml | hugging_face_repo_id>"
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
MODEL_ENTRY=$(yq ".models[] | select(.key == \"$MODEL_KEY_OR_REPO_ID\")" "$MODELS_FILE")

if [ -n "$MODEL_ENTRY" ]; then
  # --- Case 1: A known key was provided (from models.yaml) ---
  echo "✅ Found key '$MODEL_KEY_OR_REPO_ID' in $MODELS_FILE. Configuring from manifest."

  HF_MODEL_NAME=$(echo "$MODEL_ENTRY" | yq -r '.name')
  KOBOLDCPP_MODEL_NAME=$(echo "$MODEL_ENTRY" | yq -r '.koboldcpp_model_name // ""')
  CONTEXT_SIZE=$(echo "$MODEL_ENTRY" | yq -r '.default_max_context_length // 8192')

  # Trigger GGUF download for KoboldCPP if defined
  if [ -n "$KOBOLDCPP_MODEL_NAME" ] && [ "$KOBOLDCPP_MODEL_NAME" != "null" ]; then
      echo "Attempting to download GGUF model for KoboldCPP: $KOBOLDCPP_MODEL_NAME"
      # We must also trigger the full HF repo download for vLLM
      ./scripts/download-hf-model.sh "$HF_MODEL_NAME" || true
      ./scripts/download-gguf-model.sh "$MODEL_KEY_OR_REPO_ID" || true
  else
      echo "No KoboldCPP model defined for '$MODEL_KEY_OR_REPO_ID'. Triggering vLLM download only."
      ./scripts/download-hf-model.sh "$HF_MODEL_NAME" || true
  fi

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
  # --- Case 2: An unknown key or a raw Hugging Face repo ID was provided ---
  echo "⚠️ Key '$MODEL_KEY_OR_REPO_ID' not found in $MODELS_FILE. Treating as a dynamic Hugging Face repo ID for vLLM."

  HF_MODEL_NAME="$MODEL_KEY_OR_REPO_ID"
  KOBOLDCPP_MODEL_NAME="" # Disable KoboldCPP for dynamic repo IDs
  CONTEXT_SIZE="8192" # Use a safe default context size

  # Trigger download of the full Hugging Face repository
  echo "Attempting to download full Hugging Face repository: $HF_MODEL_NAME"
  ./scripts/download-hf-model.sh "$HF_MODEL_NAME" || true # Allow failure (e.g., if HF_TOKEN is missing for gated model)

  update_env "MODEL_NAME" "$HF_MODEL_NAME"
  update_env "KOBOLDCPP_MODEL_NAME" "$KOBOLDCPP_MODEL_NAME"
  update_env "MODEL_CONTEXT_SIZE" "$CONTEXT_SIZE"
  update_env "OLLM_API_BASE_URL" "http://vllm:8000/v1"

  echo "----------------------------------------"
  echo "Model configured for dynamic loading:"
  echo "  vLLM Model:       $HF_MODEL_NAME"
  echo "  Context Size:     $CONTEXT_SIZE"
  echo ""
  echo "🔴 NOTE: KoboldCPP has been disabled for this model because the specific"
  echo "   GGUF filename is unknown or not applicable. vLLM will use the directly"
  echo "   downloaded Hugging Face repository model."
  echo "----------------------------------------"
fi