#!/bin/bash
# manage.sh - A unified management script for the BEND stack.

set -e
BEND_ROOT=$(git rev-parse --show-toplevel)
cd "$BEND_ROOT"

# --- Environment Loading ---
# Get the directory where the script is located to reliably find the .env file.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
  # Use 'set -o allexport' to export all variables defined in the .env file
  # to the environment of this script and its child processes.
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
else
  # This is a non-fatal warning because the .env might not be needed for all commands.
  echo "Warning: .env file not found at '$ENV_FILE'. Healthchecks for secured services may fail."
fi

# --- Default Configuration ---
COMMAND=$1
shift # The rest of the arguments are now in $@

# --- Function to display help ---
show_help() {
  echo "Usage: ./scripts/manage.sh <command> [options] [service]"
  echo ""
  echo "Commands:"
  echo "  up            Start services."
  echo "  down [-v]     Stop all services. Use -v to remove volumes."
  echo "  restart       Restart services."
  echo "  logs          Tail logs."
  echo "  status        Show the status of running containers."
  echo "  rebuild       Force a rebuild of all images without using cache."
  echo "  healthcheck   Run a healthcheck on key services."
  echo ""
  echo "Options:"
  echo "  --gpu         Enable GPU acceleration."
  echo "  --lite        Use the lite configuration. Can be followed by an optional profile."
  echo "  <profile>     Optional after --lite. Choose 'vllm' or 'ollama', or leave blank for both."
  echo "  [service]     Optionally specify a single service to target."
  echo ""
  echo "Examples:"
  echo "  ./scripts/manage.sh up --gpu                       # Start full stack with GPU"
  echo "  ./scripts/manage.sh up --lite vllm --gpu           # Start lite stack with vLLM on GPU"
  echo "  ./scripts/manage.sh up --lite ollama               # Start lite stack with Ollama on CPU"
  echo "  ./scripts/manage.sh up --lite                      # Start lite stack with BOTH vLLM and Ollama"
  echo "  ./scripts/manage.sh logs vllm                      # Tail logs for just the vllm service"
}

# --- Argument Parsing ---
LITE_MODE=false
LITE_PROFILE_ARGS=""
SERVICE=""
GPU_FLAG=""
DOWN_FLAGS=""
TEMP_ARGS=() # Use an array to handle non-flag arguments robustly

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gpu)
      GPU_FLAG="--gpu"
      shift
      ;;
    --lite)
      LITE_MODE=true
      # Check if the next argument is a valid profile, but don't require it.
      if [[ -n "$2" && ("$2" == "vllm" || "$2" == "ollama") ]]; then
        LITE_PROFILE_ARGS="--profile $2"
        echo "💡 Lite mode enabled with profile: $2"
        shift 2
      else
        echo "💡 Lite mode enabled with all profiles (vllm & ollama)."
        LITE_PROFILE_ARGS="--profile vllm --profile ollama"
        shift
      fi
      ;;
    -v)
      DOWN_FLAGS="-v"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      # Collect non-flag arguments (should only be the service name)
      TEMP_ARGS+=("$1")
      shift
      ;;
  esac
done

# Process any remaining non-flag arguments
if [ ${#TEMP_ARGS[@]} -gt 1 ]; then
    echo "Error: Multiple services specified or unknown arguments: ${TEMP_ARGS[*]}"
    show_help
    exit 1
elif [ ${#TEMP_ARGS[@]} -eq 1 ]; then
    SERVICE=${TEMP_ARGS[0]}
fi

# --- Build the docker-compose command string ---
COMPOSE_CMD="docker compose"

if [ "$LITE_MODE" == "true" ]; then
    COMPOSE_CMD="$COMPOSE_CMD -f docker-compose.lite.yml"
    if [ -n "$LITE_PROFILE_ARGS" ]; then
        COMPOSE_CMD="$COMPOSE_CMD $LITE_PROFILE_ARGS"
    fi
else
    COMPOSE_CMD="$COMPOSE_CMD -f docker-compose.yml"
fi

if [ "$GPU_FLAG" == "--gpu" ];
then
    COMPOSE_CMD="$COMPOSE_CMD -f docker-compose.gpu.yml"
    echo "✅ GPU acceleration enabled."
    # Set build-time arguments for services that need them
    export WHISPER_GPU_ENABLED=true
else
    export WHISPER_GPU_ENABLED=false
fi


# --- Command Execution ---
case "$COMMAND" in
  up)
    echo "Starting BEND services..."
    $COMPOSE_CMD up -d --remove-orphans $SERVICE
    ;;
  down)
    echo "Stopping BEND services..."
    # The 'down' command should be aware of all possible configurations to ensure it stops everything.
    docker compose -f docker-compose.yml -f docker-compose.lite.yml down --remove-orphans $DOWN_FLAGS $SERVICE
    ;;
  restart)
    echo "Restarting BEND services..."
    $COMPOSE_CMD restart $SERVICE
    ;;
  logs)
    echo "Tailing logs..."
    $COMPOSE_CMD logs -f $SERVICE
    ;;
  status)
    echo "Checking status..."
    $COMPOSE_CMD ps $SERVICE
    ;;
  rebuild)
    echo "Rebuilding all images..."
    $COMPOSE_CMD build --no-cache $SERVICE
    ;;
  healthcheck)
    ./scripts/healthcheck.py
    ;;
  *)
    echo "Error: Unknown command '$COMMAND'"
    show_help
    exit 1
    ;;
esac