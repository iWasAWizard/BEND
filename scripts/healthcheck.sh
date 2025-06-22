#!/bin/bash

# BEND Stack Health Check
# This script checks the status of all services defined in the BEND stack.

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Service Definitions ---
# Each service is an array: (Name Port "Check Command")
# The check command should exit with 0 on success.
# Using 'nc -z' for a basic port check is fast and reliable.
# Using 'curl' for API services to ensure they are responding to requests.
services=(
    # Core API Services
    "KoboldCPP      | 12009 | curl -s -o /dev/null http://localhost:12009/api/v1/model"
    "Retriever API  | 12007 | curl -s -f -o /dev/null http://localhost:12007/documents"
    "Voice Proxy    | 12008 | nc -z localhost 12008"
    # UI
    "OpenWebUI      | 12002 | nc -z localhost 12002"
    # Backing Services
    "Qdrant         | 12006 | nc -z localhost 12006"
    "Whisper STT    | 12003 | nc -z localhost 12003"
    "Piper TTS      | 12004 | nc -z localhost 12004"
    "Glances        | 12005 | nc -z localhost 12005"
)

echo -e "${YELLOW}BEND Service Health Check${NC}"
echo "---------------------------"

all_online=true

for service_def in "${services[@]}"; do
    # Parse the service definition string
    IFS='|' read -r name port command <<< "$service_def"

    # Trim whitespace from variables
    name=$(echo "$name" | xargs)
    port=$(echo "$port" | xargs)
    command=$(echo "$command" | xargs)

    printf "Checking %-15s (Port %-5s)... " "$name" "$port"

    # Execute the check command quietly
    if eval "$command" &> /dev/null; then
        echo -e "[ ${GREEN}✅ ONLINE${NC} ]"
    else
        echo -e "[ ${RED}❌ OFFLINE${NC} ]"
        all_online=false
    fi
done

echo "---------------------------"
if [ "$all_online" = true ]; then
    echo -e "${GREEN}All BEND services are operational.${NC}"
else
    echo -e "${RED}One or more BEND services are offline. Check container logs.${NC}"
    exit 1
fi