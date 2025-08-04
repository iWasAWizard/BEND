#!/bin/bash
# BEND/scripts/entrypoint-ollama.sh
# Reverted to the simple, robust version for pulling public models.
set -e

# 1. Start the Ollama server in the background
/bin/ollama serve &
pid=$!
echo "Ollama server started with PID $pid."

# 2. Wait for the server to be ready
echo "Waiting for Ollama server to be ready..."
timeout=60
while ! curl -s --fail -o /dev/null http://localhost:11434; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
        echo "Error: Ollama server did not start within 60 seconds."
        exit 1
    fi
done
echo "Ollama server is ready."

# 3. Pull the specified public model.
if [ -n "$OLLAMA_PULL_MODEL" ]; then
  echo "Checking for model: $OLLAMA_PULL_MODEL"

  if ! /bin/ollama list | grep -q "^$OLLAMA_PULL_MODEL"; then
    echo "Model not found locally. Pulling from Ollama hub..."
    /bin/ollama pull "$OLLAMA_PULL_MODEL"
    echo "Model pull complete."
  else
    echo "Model '$OLLAMA_PULL_MODEL' already exists. Skipping pull."
  fi
else
  echo "No OLLAMA_PULL_MODEL specified. Skipping model pull."
fi

# 4. Wait for the Ollama server process to finish.
echo "Ollama container is fully configured. Tailing server process."
wait $pid