#!/bin/bash
# BEND/scripts/switch-model.sh

set -e
cd "$(dirname "$0")/.." # Move to BEND root directory

# --- Helper Function ---
# Idempotently sets a variable in the .env file.
# Updates the value if the key exists, otherwise appends the key-value pair.
# Usage: set_env_var "KEY" "VALUE"
set_env_var() {
    local key=$1
    local value=$2
    local file=".env"

    # Ensure the file exists before trying to modify it
    touch "$file"

    # Check if the key already exists (match the start of the line)
    if grep -q "^${key}=" "$file"; then
        # Key exists, so replace the line.
        # Using a different separator for sed to handle URLs gracefully.
        # The -i '' syntax is required for macOS/BSD sed compatibility.
        sed -i '' "s|^${key}=.*|${key}=${value}|" "$file"
    else
        # Key does not exist, so append it.
        echo "${key}=${value}" >> "$file"
    fi
}


# --- Main Logic ---
MODEL_ALIAS=$1
MODELS_FILE="models.yaml"

# 1. Check for 'yq' dependency
if ! command -v yq &> /dev/null; then
    echo -e "\033[0;31mERROR: 'yq' is not installed.\033[0m"
    echo "Please install yq to use this script (e.g., 'brew install yq' or 'pip install yq')."
    exit 1
fi

# 2. Check for model alias argument
if [ -z "$MODEL_ALIAS" ]; then
    echo -e "\033[0;31mERROR: No model alias provided.\033[0m"
    echo "Usage: $0 <model_alias>"
    echo -e "\nAvailable model aliases in ${MODELS_FILE}:"
    yq e '.models[].key' "$MODELS_FILE" | sed 's/^/- /'
    exit 1
fi

echo "Attempting to switch KoboldCPP model to '$MODEL_ALIAS'..."

# 3. Parse models.yaml to find the model info
MODEL_FILENAME=$(yq e '.models[] | select(.key == "'"$MODEL_ALIAS"'") | .backend_model_name' "$MODELS_FILE")
CONTEXT_SIZE=$(yq e '.models[] | select(.key == "'"$MODEL_ALIAS"'") | .default_max_context_length' "$MODELS_FILE")

# 4. Validate that the model was found
if [ -z "$MODEL_FILENAME" ] || [ "$MODEL_FILENAME" == "null" ]; then
    echo -e "\033[0;31mERROR: Model alias '$MODEL_ALIAS' not found in ${MODELS_FILE}.\033[0m"
    echo "Please choose from the available aliases:"
    yq e '.models[].key' "$MODELS_FILE" | sed 's/^/- /'
    exit 1
fi

# 5. Set the environment variables idempotently
set_env_var "MODEL_NAME" "$MODEL_FILENAME"
set_env_var "MODEL_CONTEXT_SIZE" "$CONTEXT_SIZE"

echo -e "\033[0;32mSUCCESS: KoboldCPP model configuration updated in .env file:\033[0m"
echo "  - MODEL_NAME=${MODEL_FILENAME}"
echo "  - MODEL_CONTEXT_SIZE=${CONTEXT_SIZE}"
echo "Run './scripts/switch-backend.sh koboldcpp' and then './scripts/manage.sh up' to apply."