#!/bin/bash

# BEND Stack Management Script
# Manages the services defined in docker-compose.yml.

# Change to the script's directory to ensure docker-compose.yml is found.
cd "$(dirname "$0")/.." || exit

# --- Helper Functions ---
print_usage() {
    echo "Usage: $0 {up|up-debug|down|status|logs|switch|build|list|airgap-bundle} [--gpu]"
    echo "  up [--gpu]        - Start all services in detached mode."
    echo "  up-debug [--gpu]  - Start all services in the foreground to stream logs."
    echo "  down              - Stop all services."
    echo "  status            - Show the status of all services."
    echo "  logs [service]    - Tail logs for a specific service (e.g., koboldcpp)."
    echo "  switch [model_key]- Switch the active LLM model."
    echo "  build [--gpu]     - Build all service images. Use --gpu for NVIDIA."
    echo "  list              - List available models from models.yaml."
    echo "  airgap-bundle     - Download all models and Docker images for offline deployment."
}

ensure_piper_model_exists() {
    local model_dir="piper"
    local model_name="en_US-lessac-medium.onnx"
    local model_file="$model_dir/$model_name"
    local config_file="$model_file.json"

    mkdir -p "$model_dir"

    if [ ! -f "$model_file" ] || [ ! -f "$config_file" ]; then
        echo "==> Piper voice model not found. Downloading required files..."
        if ! command -v wget &> /dev/null; then
            echo "Error: wget is not installed. Please install it to download the model."
            exit 1
        fi
        local base_url="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium"
        if [ ! -f "$model_file" ]; then
            wget -q --show-progress -O "$model_file" "$base_url/$model_name"
        fi
        if [ ! -f "$config_file" ]; then
            wget -q --show-progress -O "$config_file" "$base_url/$model_name.json"
        fi
        echo "✅ Piper model downloaded successfully."
    else
        echo "✅ Piper voice model found."
    fi
}

list_models() {
    if ! command -v yq &> /dev/null; then
        echo "Error: yq is not installed. Please install it to list models."
        exit 1
    fi

    echo "Available Models (from models.yaml):"
    printf "%-20s | %-40s | %-10s | %s\n" "Key" "Name" "Context" "Use Case"
    echo "-------------------------------------------------------------------------------------------------------"

    yq e '.models[] | .key + " | " + .name + " | " + .default_max_context_length + " | " + .use_case' models.yaml | \
    while IFS="|" read -r key name context use_case; do
        # Trim whitespace
        key=$(echo "$key" | xargs)
        name=$(echo "$name" | xargs)
        context=$(echo "$context" | xargs)
        use_case=$(echo "$use_case" | xargs)
        printf "%-20s | %-40s | %-10s | %s\n" "$key" "$name" "$context" "$use_case"
    done
}


# --- Main Logic ---
ACTION=${1}
shift || true

# Base docker-compose command setup
COMPOSE_FILES="-f docker-compose.yml"
BUILD_ARGS=""

# Check for --gpu flag in the remaining arguments
if [[ " $@ " =~ " --gpu " ]]; then
    echo "🚀 GPU mode enabled. Applying NVIDIA configurations."
    BUILD_ARGS="--build-arg GPU_ENABLED=true"
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.gpu.yml"
fi

case "$ACTION" in
    up)
        ensure_piper_model_exists
        echo "==> Building and starting BEND services in detached mode..."
        docker compose $COMPOSE_FILES up -d --build $BUILD_ARGS
        ;;
    up-debug)
        ensure_piper_model_exists
        echo "==> Building and starting BEND services in foreground (debug mode)..."
        docker compose $COMPOSE_FILES up --build $BUILD_ARGS
        ;;
    down)
        echo "==> Stopping BEND services..."
        docker compose $COMPOSE_FILES down
        ;;
    status)
        echo "==> BEND Service Status:"
        docker compose $COMPOSE_FILES ps
        ;;
    logs)
        SERVICE=${1:-"koboldcpp"}
        echo "==> Tailing logs for '$SERVICE' (Ctrl+C to exit)..."
        docker compose $COMPOSE_FILES logs -f "$SERVICE"
        ;;
    switch)
        MODEL_KEY=${1}
        if [ -z "$MODEL_KEY" ]; then
            echo "Error: You must provide a model key."
            exit 1
        fi
        echo "==> Switching model to '$MODEL_KEY'..."
        ./scripts/switch-model.sh "$MODEL_KEY"
        ;;
    build)
        echo "==> Building all BEND service images..."
        docker compose $COMPOSE_FILES build $BUILD_ARGS
        ;;
    list)
        list_models
        ;;
    airgap-bundle)
        echo "==> Preparing BEND airgap bundle..."
        # 1. Download all models
        ./scripts/download-all-models.sh
        # 2. Pull all docker images
        echo "==> Pulling all required Docker images for BEND..."
        docker compose $COMPOSE_FILES pull
        # 3. Save images to a tarball
        echo "==> Saving images to bend-images.tar..."
        docker save $(docker compose $COMPOSE_FILES config --images) -o bend-images.tar
        echo "✅ BEND airgap bundle preparation complete."
        ;;
    *)
        print_usage
        exit 1
        ;;
esac