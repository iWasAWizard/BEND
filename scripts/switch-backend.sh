#!/bin/bash
# BEND/scripts/switch-backend.sh

set -e
cd "$(dirname "$0")/.." # Move to BEND root directory

BACKEND=$1
ENV_FILE=".env"

# --- Helper Function ---
# Idempotently sets a variable in the .env file.
# Updates the value if the key exists, otherwise appends the key-value pair.
# Usage: set_env_var "KEY" "VALUE"
set_env_var() {
    local key=$1
    local value=$2

    # Ensure the file exists before trying to modify it
    touch "$ENV_FILE"

    # Check if the key already exists (match the start of the line)
    if grep -q "^${key}=" "$ENV_FILE"; then
        # Key exists, so replace the line.
        # Using a different separator for sed to handle URLs gracefully.
        # The -i '' syntax is required for macOS/BSD sed compatibility.
        sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
        # Key does not exist, so append it.
        echo "${key}=${value}" >> "$ENV_FILE"
    fi
}


# --- Main Logic ---

if [ -z "$BACKEND" ]; then
    echo "Usage: $0 [koboldcpp|ollama]"
    exit 1
fi

echo "Switching BEND LLM backend to: $BACKEND"

# Stop any running services to ensure a clean switch
if [ -f "$ENV_FILE" ]; then
    echo "Stopping existing BEND services..."
    # Suppress "file not found" errors if compose files aren't present
    ./scripts/manage.sh down 2>/dev/null || true
fi

# Configure for the selected backend
if [ "$BACKEND" == "ollama" ]; then
    set_env_var "BEND_LLM_BACKEND" "ollama"
    set_env_var "OLLM_API_BASE_URL" "http://ollama:11434"
    echo "Ollama backend selected. OpenWebUI will connect to the Ollama API."
    echo "You can now run './scripts/manage.sh up'. Once up, pull models with 'docker exec ollama ollama pull <model_name>'."

elif [ "$BACKEND" == "koboldcpp" ]; then
    set_env_var "BEND_LLM_BACKEND" "koboldcpp"
    set_env_var "OLLM_API_BASE_URL" "http://koboldcpp:5001/v1"
    echo "KoboldCPP backend selected. OpenWebUI will connect to the KoboldCPP OpenAI-compatible endpoint."
    echo "Ensure you have run './scripts/switch-model.sh' to select a GGUF model."

else
    echo "Error: Unknown backend '$BACKEND'. Please choose 'koboldcpp' or 'ollama'."
    exit 1
fi

# Ensure script is executable
chmod +x scripts/manage.sh

echo "Backend switched successfully. Your '.env' file has been updated cleanly."