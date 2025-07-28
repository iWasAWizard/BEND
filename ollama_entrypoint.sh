#!/bin/bash
# ollama_entrypoint.sh
# This script starts the Ollama server in the background, waits for it to be
# ready, and then automatically pulls a model if specified.

set -e

# Start the Ollama server in the background
/bin/ollama serve &
# Capture the PID of the server process
pid=$!

# Wait for the server to be up and running
echo "Waiting for Ollama server to start..."
until curl -s -f http://localhost:11434/ > /dev/null; do
    sleep 1
done
echo "✅ Ollama server is up."

# Check if a model is specified to be pulled
if [ -n "$OLLAMA_PULL_MODEL" ]; then
    echo "Pulling model: $OLLAMA_PULL_MODEL..."
    ollama pull "$OLLAMA_PULL_MODEL"
    echo "✅ Model pulled successfully."
else
    echo "No OLLAMA_PULL_MODEL specified, skipping auto-pull."
fi

# Wait for the server process to exit
wait $pid