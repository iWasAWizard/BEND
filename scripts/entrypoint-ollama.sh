#!/bin/bash
# BEND/scripts/entrypoint-ollama.sh
# Custom entrypoint for the Ollama container to automatically pull a model on startup.

set -e

# Start the Ollama server in the background
/bin/ollama serve &
pid=$!

echo "Ollama server started with PID $pid."
# Give the server a moment to initialize.
# We'll use curl to check if the API is up before proceeding.
echo "Waiting for Ollama server to be ready..."
timeout=30
while ! curl -s -o /dev/null http://localhost:11434; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
        echo "Error: Ollama server did not start within 30 seconds."
        exit 1
    fi
done
echo "Ollama server is ready."


# Check if a model name is provided in the environment
if [ -n "$OLLAMA_PULL_MODEL" ]; then
  echo "Checking for model: $OLLAMA_PULL_MODEL"
  # Use 'ollama list' to check if the model already exists
  if ! /bin/ollama list | grep -q "^$OLLAMA_PULL_MODEL"; then
    echo "Model not found locally. Pulling from Ollama hub..."
    /bin/ollama pull "$OLLAMA_PULL_MODEL"
    echo "✅ Model pull complete."
  else
    echo "✅ Model '$OLLAMA_PULL_MODEL' already exists. Skipping pull."
  fi
else
  echo "⚠️ No OLLAMA_PULL_MODEL specified. The container will start without automatically pulling a model."
fi

# Wait for the Ollama server process to exit, which will keep the container running.
wait $pid