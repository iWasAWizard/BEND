#!/bin/bash
set -e

# BEND STT Model Downloader
# This script downloads the required GGML model for the whisper.cpp container.

cd "$(dirname "$0")/.."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MODEL_NAME="ggml-base.en.bin"
STT_MODELS_DIR="stt-models"
DEST_PATH="${STT_MODELS_DIR}/${MODEL_NAME}"
URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL_NAME}"

mkdir -p "$STT_MODELS_DIR"

if [ -f "$DEST_PATH" ]; then
    echo -e "${GREEN}STT model '${MODEL_NAME}' already exists. Skipping download.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Downloading STT Model:${NC} ${MODEL_NAME}"
echo -e "${YELLOW}To Destination:${NC} ${DEST_PATH}\n"

wget -O "$DEST_PATH" --progress=bar:force "$URL"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ STT model download complete!${NC}"
else
    echo -e "\n${RED}❌ STT model download failed.${NC}"
    rm -f "$DEST_PATH"
    exit 1
fi