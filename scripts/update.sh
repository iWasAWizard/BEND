#!/bin/bash
set -e
echo "[+] Pulling latest Docker images..."
docker compose pull

echo "[+] TODO: Check HuggingFace model versions and auto-download new releases."

echo "[✓] Update complete."

