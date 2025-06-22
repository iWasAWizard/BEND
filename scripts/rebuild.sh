#!/bin/bash
# rebuild.sh - Full teardown & resurrection of BEND

set -e

echo "🔥 [BEND] INITIATING SYSTEM PURGE..."
docker compose down --volumes
docker system prune -af --volumes

echo "🔧 [BEND] BUILDING CONTAINERS..."
docker compose build

echo "🚀 [BEND] LAUNCHING STACK..."
docker compose up -d

MODEL_NAME=$(grep MODEL_NAME .env | cut -d '=' -f2)

echo "🧠 [BEND] MODEL STATUS:"
if [ -f "models/$MODEL_NAME" ]; then
  echo "✅ Model found: $MODEL_NAME"
else
  echo "❌ Model missing: $MODEL_NAME"
  echo "→ Attempting download using models.yaml..."
  ./switch-model.sh "$(yq e ".models[] | select(.filename == \"$MODEL_NAME\") | .key" models.yaml)"
fi

echo "🩺 [BEND] RUNNING HEALTH CHECKS..."
./healthcheck.sh || echo "⚠️ Some services failed healthcheck."

echo "✅ [BEND] COMPLETE. READY FOR DEPLOYMENT."

