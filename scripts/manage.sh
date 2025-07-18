#!/bin/bash

# A simple management script for the BEND stack.
# Use this to start, stop, and manage the backend services.

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
print_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}WARN: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# --- Main Logic ---
cd "$(dirname "$0")/.." # Ensure we are in the BEND root directory

COMMAND=$1
shift || true # Shift arguments, allowing us to pass the rest to docker-compose

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Determine which backend compose file to use based on the .env variable
BACKEND_COMPOSE_FILE=""
if [ "$BEND_LLM_BACKEND" == "ollama" ]; then
    BACKEND_COMPOSE_FILE="-f docker-compose.ollama.yml"
elif [ "$BEND_LLM_BACKEND" == "koboldcpp" ]; then
    BACKEND_COMPOSE_FILE="-f docker-compose.koboldcpp.yml"
else
    print_warn "BEND_LLM_BACKEND not set in .env. No LLM service will be started."
    print_warn "Run './scripts/switch-backend.sh [koboldcpp|ollama]' to configure."
fi

# Check for --gpu flag in the remaining arguments
GPU_FLAG=""
if [[ " $@ " =~ " --gpu " ]]; then
  GPU_FLAG="-f docker-compose.gpu.yml"
  # This is a simple way to filter out the flag; a more robust script would parse args properly
  set -- "${@/--gpu/}"
fi

# Construct the base docker-compose command with all necessary files
BASE_CMD="docker compose -f docker-compose.yml ${BACKEND_COMPOSE_FILE} ${GPU_FLAG}"

if [ -z "$COMMAND" ]; then
    print_error "No command specified."
    echo "Usage: $0 {up|down|rebuild|logs|status|healthcheck} [--gpu] [docker-compose-args...]"
    exit 1
fi

case "$COMMAND" in
    up)
        print_info "Starting BEND stack with backend: ${BEND_LLM_BACKEND:-none}"
        $BASE_CMD up -d --remove-orphans "$@"
        print_success "BEND stack started. Use 'healthcheck' to verify services."
        ;;

    down)
        print_info "Stopping BEND stack..."
        $BASE_CMD down "$@"
        print_success "BEND stack stopped."
        ;;

    rebuild)
        print_info "Force rebuilding BEND stack..."
        $BASE_CMD build --no-cache "$@"
        print_success "Rebuild complete. Use 'up' to start."
        ;;

    logs)
        print_info "Tailing logs... (Ctrl+C to exit)"
        $BASE_CMD logs -f "$@"
        ;;

    status)
        print_info "--- BEND Stack Status ---"
        $BASE_CMD ps "$@"
        ;;

    healthcheck)
        print_info "Performing healthcheck..."
        if [ ! -f "scripts/healthcheck.py" ]; then
            print_error "Healthcheck script not found at scripts/healthcheck.py"
            exit 1
        fi
        python3 scripts/healthcheck.py
        ;;

    *)
        print_error "Unknown command: '$COMMAND'"
        echo "Usage: $0 {up|down|rebuild|logs|status|healthcheck} [--gpu] [docker-compose-args...]"
        exit 1
        ;;
esac
