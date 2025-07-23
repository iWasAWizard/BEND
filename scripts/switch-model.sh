# BEND/scripts/switch-model.sh
#!/bin/bash
# A script to switch the active LLM by updating the .env file.
# It reads model metadata from models.yaml using yq.

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Main Logic ---
cd "$(dirname "$0")/.." || exit # Ensure we are in the BEND root directory

if [ -z "$1" ]; then
    echo -e "${RED}ERROR: No model key provided.${NC}"
    echo "Usage: $0 <model_key>"
    echo "Example: $0 hermes"
    echo -e "\nAvailable model keys from models.yaml:"
    yq e '.models[].key' models.yaml
    exit 1
fi

MODEL_KEY=$1
ENV_FILE=".env"

# Use yq to find the model entry by its key and extract its properties
MODEL_DATA=$(yq e ".models[] | select(.key == \"$MODEL_KEY\")" models.yaml)

if [ -z "$MODEL_DATA" ]; then
    echo -e "${RED}ERROR: Model key '$MODEL_KEY' not found in models.yaml.${NC}"
    exit 1
fi

# Extract the required fields using yq
MODEL_NAME=$(echo "$MODEL_DATA" | yq e '.name' -)
KOBOLDCPP_MODEL_NAME=$(echo "$MODEL_DATA" | yq e '.backend_model_name' -)
CONTEXT_SIZE=$(echo "$MODEL_DATA" | yq e '.default_max_context_length' -)

echo -e "${BLUE}Switching to model: ${YELLOW}$MODEL_NAME${NC}"

# --- Non-destructive .env update ---
touch "$ENV_FILE" # Create the file if it doesn't exist

update_or_add_line() {
    local key="$1"
    local value="$2"
    local file="$3"
    if grep -q "^${key}=" "$file"; then
        # Key exists, so we update it. Using a temp file for sed is safer.
        sed -i.bak "s|^${key}=.*|${key}=${value}|" "$file"
        rm "${file}.bak"
    else
        # Key does not exist, so we append it.
        echo "${key}=${value}" >> "$file"
    fi
}

update_or_add_line "MODEL_NAME" "$MODEL_NAME" "$ENV_FILE"
update_or_add_line "KOBOLDCPP_MODEL_NAME" "$KOBOLDCPP_MODEL_NAME" "$ENV_FILE"
update_or_add_line "MODEL_CONTEXT_SIZE" "$CONTEXT_SIZE" "$ENV_FILE"
update_or_add_line "VLLM_GPU_MEMORY_UTILIZATION" "0.90" "$ENV_FILE"
update_or_add_line "KOBOLD_GPU_LAYERS" "50" "$ENV_FILE"
update_or_add_line "WHISPER_GPU_LAYERS" "99" "$ENV_FILE"
update_or_add_line "OLLM_API_BASE_URL" "http://vllm:8000/v1" "$ENV_FILE"

echo -e "${GREEN}SUCCESS: .env file has been configured for '$MODEL_KEY'.${NC}"
echo "User-defined variables in .env have been preserved."
echo "You can now start the stack with './scripts/manage.sh up'"