#!/bin/bash
set -e

# Base URL for Piper voice models on Hugging Face
BASE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main"

# Check if a voice name was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <voice_name>"
  echo "Example: $0 en_US-libritts-high"
  echo "Find more voices at: https://huggingface.co/rhasspy/piper-voices/tree/main"
  exit 1
fi

VOICE_NAME="$1"
# Assumes the first two letters of the voice name are the language code (e.g., 'en' from 'en_US-...')
LANG_CODE=$(echo "$VOICE_NAME" | cut -c1-2)

VOICE_DIR="./piper"
ONNX_FILE="${VOICE_NAME}.onnx"
JSON_FILE="${ONNX_FILE}.json"

MODEL_URL="${BASE_URL}/${LANG_CODE}/${VOICE_NAME}/${ONNX_FILE}"
JSON_URL="${BASE_URL}/${LANG_CODE}/${VOICE_NAME}/${JSON_FILE}"

# Create the piper directory if it doesn't exist
mkdir -p "$VOICE_DIR"

echo "Downloading voice model: ${ONNX_FILE}..."
if ! curl -f -L -o "${VOICE_DIR}/${ONNX_FILE}" "$MODEL_URL"; then
    echo "Error: Failed to download model file from ${MODEL_URL}"
    echo "Please check the voice name and that it exists on the Hugging Face Hub."
    exit 1
fi

echo "Downloading voice config: ${JSON_FILE}..."
if ! curl -f -L -o "${VOICE_DIR}/${JSON_FILE}" "$JSON_URL"; then
    echo "Error: Failed to download config file from ${JSON_URL}"
    # Clean up the downloaded model file if the config download fails
    rm "${VOICE_DIR}/${ONNX_FILE}"
    exit 1
fi

echo ""
echo "✅ Success! Voice '${VOICE_NAME}' downloaded to '${VOICE_DIR}'."
echo ""
echo "To use this voice, set the following in your .env file:"
echo "PIPER_VOICE=${ONNX_FILE}"
echo ""
echo "Then, restart the stack: docker compose up -d --force-recreate piper"