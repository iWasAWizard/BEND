# BEND/scripts/download-model.sh
#!/bin/bash
# A utility to download a specific GGUF model from models.yaml into the ./models directory.

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

cd "$(dirname "$0")/.." || exit # Ensure we are in the BEND root directory

if [ -z "$1" ]; then
    echo -e "${RED}ERROR: No model key provided.${NC}"
    echo "Usage: $0 <model_key>"
    echo "Example: $0 hermes"
    exit 1
fi

MODEL_KEY=$1
MODELS_DIR="models"
mkdir -p "$MODELS_DIR"

MODEL_DATA=$(yq e ".models[] | select(.key == \"$MODEL_KEY\")" models.yaml)

if [ -z "$MODEL_DATA" ]; then
    echo -e "${RED}ERROR: Model key '$MODEL_KEY' not found in models.yaml.${NC}"
    exit 1
fi

MODEL_URL=$(echo "$MODEL_DATA" | yq e '.url' -)
MODEL_FILENAME=$(echo "$MODEL_DATA" | yq e '.backend_model_name' -)

if [ -z "$MODEL_URL" ] || [ "$MODEL_URL" == "null" ]; then
    echo -e "${RED}ERROR: No download URL found for model '$MODEL_KEY' in models.yaml.${NC}"
    exit 1
fi

if [ -f "$MODELS_DIR/$MODEL_FILENAME" ]; then
    echo -e "${YELLOW}WARN: Model file '$MODEL_FILENAME' already exists. Skipping download.${NC}"
    exit 0
fi

echo -e "${BLUE}Downloading model for '$MODEL_KEY'...${NC}"
echo "URL: $MODEL_URL"
echo "Destination: $MODELS_DIR/$MODEL_FILENAME"

wget -O "$MODELS_DIR/$MODEL_FILENAME" "$MODEL_URL"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: Model downloaded successfully.${NC}"
else
    echo -e "${RED}ERROR: Download failed. Please check the URL and your network connection.${NC}"
    # Clean up partially downloaded file
    rm -f "$MODELS_DIR/$MODEL_FILENAME"
    exit 1
fi