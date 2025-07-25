#!/bin/bash
# scripts/download-hf-model.sh
# Clones a full model repository from Hugging Face into the ./models directory.
# It automatically uses the HF_TOKEN from the .env file if it exists,
# which is required for gated models like Llama 3.

set -e
BEND_ROOT=$(git rev-parse --show-toplevel)
cd "$BEND_ROOT"

REPO_ID=$1
MODELS_DIR="models"
ENV_FILE=".env"

if [ -z "$REPO_ID" ]; then
  echo "Usage: $0 <hugging_face_repo_id>"
  echo "Example: $0 \"NousResearch/Nous-Hermes-2-Mistral-7B-DPO\""
  exit 1
fi

# Ensure the models directory exists
mkdir -p "$MODELS_DIR"

# Check for HF_TOKEN in the .env file and export it for the git command
if [ -f "$ENV_FILE" ]; then
  # Source the .env file to make variables available
  export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Convert repo ID to a valid directory path
# e.g., "meta-llama/Meta-Llama-3-8B-Instruct" becomes "meta-llama-Meta-Llama-3-8B-Instruct"
# But Hugging Face's own caching uses "models--meta-llama--Meta-Llama-3-8B-Instruct"
# To keep it simple and compatible with volume mounts, we will just clone it into a dir named after the repo ID.
# vLLM expects the path to be the repo ID, and it looks for it in the cache dir.
# By cloning it into ./models/ a dir with the repo ID's name, the volume mount works.
# But git clone will create a directory named after the last part of the repo ID.
# Let's handle this more robustly.

# The directory will be named after the repo ID, but with '/' replaced by '--' to mimic HF cache
TARGET_DIR_NAME="models--$(echo "$REPO_ID" | sed 's/\//--/g')"
TARGET_DIR_PATH="$MODELS_DIR/$TARGET_DIR_NAME"

if [ -d "$TARGET_DIR_PATH" ]; then
    echo "✅ Model repository for '$REPO_ID' already exists at '$TARGET_DIR_PATH'. Skipping download."
    exit 0
fi

echo "Cloning model repository '$REPO_ID' into '$TARGET_DIR_PATH'..."
echo "This may take a long time and require a lot of disk space."

# Use git-lfs to clone the repository.
# The HF_TOKEN environment variable will be used automatically for authentication.
# We clone into a temporary name and then move it to the final name to handle cache structure.
TMP_CLONE_DIR=$(mktemp -d)
git clone "https://huggingface.co/$REPO_ID" "$TMP_CLONE_DIR"
mv "$TMP_CLONE_DIR" "$TARGET_DIR_PATH"

echo "✅ Model '$REPO_ID' downloaded successfully into the '$TARGET_DIR_PATH' directory."