#!/bin/bash
set -e

# BEND Model Downloader
# This script downloads a GGUF model from the URL specified in models.yaml.

# --- Helper Functions & Variables ---
# Move to the project root directory, which is one level up from this script's location.
cd "$(dirname "$0")/.."

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MODELS_YAML="models.yaml"
MODELS_DIR="models"

# --- Input Validation ---
MODEL_KEY=$1
if [ -z "$MODEL_KEY" ]; then
    echo -e "${RED}Error: No model key provided.${NC}"
    echo "Usage: $0 <model_key>"
    echo "Example: $0 mistral"
    echo "Available keys can be found in ${MODELS_YAML}"
    exit 1
fi

# Check for dependencies
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: 'yq' is not installed. Please install it to continue.${NC}"
    echo "macOS: brew install yq"
    echo "Linux: sudo snap install yq or sudo apt-get install yq"
    exit 1
fi
if ! command -v wget &> /dev/null; then
    echo -e "${RED}Error: 'wget' is not installed. Please install it to continue.${NC}"
    exit 1
fi

# --- Script Logic ---
echo -e "${YELLOW}Searching for model key '$MODEL_KEY' in ${MODELS_YAML}...${NC}"

# Parse the YAML file to get the URL and filename
MODEL_DATA=$(yq ".models[] | select(.key == \"$MODEL_KEY\")" "$MODELS_YAML")

if [ -z "$MODEL_DATA" ]; then
    echo -e "${RED}Error: Model key '$MODEL_KEY' not found in ${MODELS_YAML}.${NC}"
    exit 1
fi

URL=$(echo "$MODEL_DATA" | yq -r '.url')
FILENAME=$(echo "$MODEL_DATA" | yq -r '.filename')

if [ -z "$URL" ] || [ "$URL" == "null" ]; then
    echo -e "${RED}Error: No download URL found for model '$MODEL_KEY' in ${MODELS_YAML}.${NC}"
    exit 1
fi

if [ -z "$FILENAME" ] || [ "$FILENAME" == "null" ]; then
    echo -e "${RED}Error: No filename found for model '$MODEL_KEY' in ${MODELS_YAML}.${NC}"
    exit 1
fi

# Ensure the models directory exists
mkdir -p "$MODELS_DIR"
echo "Models will be saved in the './${MODELS_DIR}' directory."

DEST_PATH="${MODELS_DIR}/${FILENAME}"

# Check if the file already exists
if [ -f "$DEST_PATH" ]; then
    echo -e "${GREEN}Model file '$FILENAME' already exists. Skipping download.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Downloading Model:${NC} ${FILENAME}"
echo -e "${YELLOW}From URL:${NC} ${URL}"
echo -e "${YELLOW}To Destination:${NC} ${DEST_PATH}\n"

# Use wget to download the file with a progress bar
wget -O "$DEST_PATH" --progress=bar:force "$URL"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Download complete! Model saved to '${DEST_PATH}'.${NC}"
else
    echo -e "\n${RED}❌ Download failed. Please check the URL and your network connection.${NC}"
    # Clean up partially downloaded file
    rm -f "$DEST_PATH"
    exit 1
fi