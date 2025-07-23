# BEND/scripts/list-models.sh
#!/bin/bash
# A utility to list available models from models.yaml.

cd "$(dirname "$0")/.." || exit # Ensure we are in the BEND root directory

if ! command -v yq &> /dev/null; then
    echo "ERROR: yq is not installed. Please install it to use this script."
    exit 1
fi

yq e '.models[] | .key + ": " + .use_case' models.yaml