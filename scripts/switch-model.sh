#!/bin/bash
# switch-model.sh - A smart script to configure BEND for a specific model.

# It can be used in two ways:
# 1. By KEY: ./scripts/switch-model.sh llama3
#    - Looks up 'llama3' in models.yaml.
#    - Configures vLLM and Ollama with values from the manifest.
#
# 2. By Hugging Face REPO_ID: ./scripts/switch-model.sh "mistralai/Mistral-7B-Instruct-v0.2"
#    - Treats the argument as a repo ID for vLLM.
#    - Disables Ollama for this run.

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

touch "$ENV_FILE"
MODEL_ENTRY=$(yq ".models[] | select(.key == \"$MODEL_KEY_OR_REPO_ID\")" "$MODELS_FILE")

if [ -n "$MODEL_ENTRY" ]; then
  echo "✅ Found key '$MODEL_KEY_OR_REPO_ID' in $MODELS_FILE. Configuring from manifest."

  HF_MODEL_NAME=$(echo "$MODEL_ENTRY" | yq -r '.name')
  OLLAMA_MODEL_NAME=$(echo "$MODEL_ENTRY" | yq -r '.ollama_model_name // ""')
  CONTEXT_SIZE=$(echo "$MODEL_ENTRY" | yq -r '.default_max_context_length // 8192')

  update_env "MODEL_NAME" "$HF_MODEL_NAME"
  update_env "OLLAMA_PULL_MODEL" "$OLLAMA_MODEL_NAME"
  update_env "MODEL_CONTEXT_SIZE" "$CONTEXT_SIZE"
  update_env "OLLM_API_BASE_URL" "http://vllm:8000,http://ollama:11434"

  echo "----------------------------------------"
  echo "Model configured successfully:"
  echo "  vLLM Model:       $HF_MODEL_NAME"
  echo "  Ollama Model:     $OLLAMA_MODEL_NAME"
  echo "  Context Size:     $CONTEXT_SIZE"
  echo "----------------------------------------"
else
  echo "⚠️ Key '$MODEL_KEY_OR_REPO_ID' not found. Treating as a dynamic Hugging Face repo ID for vLLM."

  HF_MODEL_NAME="$MODEL_KEY_OR_REPO_ID"
  OLLAMA_MODEL_NAME=""
  CONTEXT_SIZE="8192"

  update_env "MODEL_NAME" "$HF_MODEL_NAME"
  update_env "OLLAMA_PULL_MODEL" "$OLLAMA_MODEL_NAME"
  update_env "MODEL_CONTEXT_SIZE" "$CONTEXT_SIZE"
  update_env "OLLM_API_BASE_URL" "http://vllm:8000,http://ollama:11434"

  echo "----------------------------------------"
  echo "Model configured for dynamic vLLM loading:"
  echo "  vLLM Model:       $HF_MODEL_NAME"
  echo "🔴 NOTE: Ollama is disabled for this dynamic model."
  echo "----------------------------------------"
fi