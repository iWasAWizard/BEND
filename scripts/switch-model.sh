#!/bin/bash
set -e

# This script switches the active KoboldCPP model.
# It updates the .env file for persistence across restarts
# and then calls the KoboldCPP API to hot-swap the model without downtime.

MODEL_KEY="$1"
MODELS_FILE="models.yaml"
ENV_FILE=".env"

# 1. Validate input
if [ -z "$MODEL_KEY" ]; then
  echo "Error: No model key provided."
  echo "Usage: ./scripts/switch-model.sh <model_key>"
  echo "Available models:"
  yq '.models[].key' "$MODELS_FILE" | sed 's/^/- /'
  exit 1
fi

# 2. Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install it to continue."
    echo "macOS: brew install yq"
    echo "Linux: sudo snap install yq or sudo apt-get install yq"
    exit 1
fi

# 3. Find the model in the YAML file
MODEL_ENTRY=$(yq ".models[] | select(.key == \"$MODEL_KEY\")" "$MODELS_FILE")

if [ -z "$MODEL_ENTRY" ]; then
  echo "Error: Model key '$MODEL_KEY' not found in $MODELS_FILE"
  exit 1
fi

# 4. Parse model details
FILENAME=$(echo "$MODEL_ENTRY" | yq -r '.filename')
CONTEXT_STR=$(echo "$MODEL_ENTRY" | yq -r '.context')

# Convert context string (e.g., "16K") to a number
CONTEXT_NUM=$(echo "$CONTEXT_STR" | tr 'K' '000' | tr -d '.')

echo "Switching to model '$MODEL_KEY':"
echo "  - Filename: $FILENAME"
echo "  - Context: ${CONTEXT_STR} (${CONTEXT_NUM})"

# 5. Update .env file for persistence
if [ -f "$ENV_FILE" ]; then
    # Use sed to update existing values or append if they don't exist
    sed -i.bak -e "/^MODEL_NAME=/ s|=.*|=$FILENAME|" \
                 -e "/^MODEL_CONTEXT_SIZE=/ s|=.*|=$CONTEXT_NUM|" "$ENV_FILE"
    if ! grep -q "^MODEL_NAME=" "$ENV_FILE"; then echo "MODEL_NAME=$FILENAME" >> "$ENV_FILE"; fi
    if ! grep -q "^MODEL_CONTEXT_SIZE=" "$ENV_FILE"; then echo "MODEL_CONTEXT_SIZE=$CONTEXT_NUM" >> "$ENV_FILE"; fi
    rm "${ENV_FILE}.bak"
else
    # Create .env file if it doesn't exist
    echo "MODEL_NAME=$FILENAME" > "$ENV_FILE"
    echo "MODEL_CONTEXT_SIZE=$CONTEXT_NUM" >> "$ENV_FILE"
fi
echo "✅ .env file updated for persistence."

# 6. Call KoboldCPP API to hot-swap the model
echo "🚀 Attempting to hot-swap model via KoboldCPP API..."

# The model path must be the full path *inside the container*
MODEL_PATH_IN_CONTAINER="/models/$FILENAME"
KOBOLD_API_URL="http://localhost:12009/api/v1/model"

JSON_PAYLOAD=$(cat <<EOF
{
  "name": "$MODEL_PATH_IN_CONTAINER",
  "action": "load",
  "n_ctx": $CONTEXT_NUM
}
EOF
)

# Send the request
if curl -s -f -X POST -H "Content-Type: application/json" -d "$JSON_PAYLOAD" "$KOBOLD_API_URL" > /dev/null; then
  echo "✅ Success! Hot-swap request sent to KoboldCPP."
  echo "The model should now be available."
else
  echo "⚠️ Warning: Failed to send hot-swap request to KoboldCPP."
  echo "The service might be down or starting up."
  echo "The .env file has been updated, so the correct model will be loaded on the next stack restart."
fi