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
COMMAND=$1
ARG2=$2

if [ -z "$COMMAND" ]; then
    print_error "No command specified."
    echo "Usage: $0 {up|down|rebuild|logs|status|healthcheck} [--lite]"
    exit 1
fi

case "$COMMAND" in
    up)
        if [ "$ARG2" == "--lite" ]; then
            print_info "Starting BEND stack in LITE mode (KoboldCPP only)..."
            docker compose up -d koboldcpp
        else
            print_info "Starting BEND stack in FULL mode..."
            docker compose --profile full up -d
        fi
        print_success "BEND stack started. Use 'healthcheck' to verify services."
        ;;

    down)
        print_info "Stopping BEND stack..."
        docker compose down "$@"
        print_success "BEND stack stopped."
        ;;

    rebuild)
        print_info "Force rebuilding BEND stack..."
        docker compose build --no-cache
        print_success "Rebuild complete. Use 'up' to start."
        ;;

    logs)
        print_info "Tailing logs... (Ctrl+C to exit)"
        docker compose logs -f "$ARG2"
        ;;

    status)
        print_info "--- BEND Stack Status ---"
        docker compose ps
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
        echo "Usage: $0 {up|down|rebuild|logs|status|healthcheck} [--lite]"
        exit 1
        ;;
esac