# BEND/scripts/healthcheck.py
#!/usr/bin/env python3
"""
A simple healthcheck script for the BEND stack.
Curls the primary endpoints of each service to verify they are responsive.
"""

import os
import requests
import sys


# --- Colors for terminal output ---
class Colors:
    GREEN = "\033[0;32m"
    RED = "\033[0;31m"
    YELLOW = "\033[1;33m"
    NC = "\033[0m"


# --- Service Definitions ---
# URLs are configured to be called from the host machine, matching docker-compose ports.
SERVICES = {
    "vLLM": os.getenv("VLLM_URL", "http://localhost:12011/health"),
    "LangFuse": os.getenv("LANGFUSE_URL", "http://localhost:12012/api/public/health"),
    "Guardrails": os.getenv("GUARDRAILS_URL", "http://localhost:12013/health"),
    "Whisper": os.getenv("WHISPER_URL", "http://localhost:12003/health"),
    "Piper": os.getenv("PIPER_URL", "http://localhost:12004/"),
    "Retriever": os.getenv("RETRIEVER_URL", "http://localhost:12007/documents"),
}


def check_service(name: str, url: str) -> bool:
    """
    Checks a single service by making an HTTP GET request.

    :param name: The human-readable name of the service.
    :param url: The URL endpoint to check.
    :return: True if the service is healthy, False otherwise.
    """
    print(f"Checking {Colors.YELLOW}{name:<15}{Colors.NC}...", end="", flush=True)
    try:
        # Increased timeout for services that might be slow to start (like vLLM)
        response = requests.get(url, timeout=20)
        if 200 <= response.status_code < 400:
            print(
                f"[ {Colors.GREEN}OK{Colors.NC} ] - Responded with status {Colors.GREEN}{response.status_code}{Colors.NC}"
            )
            return True
        else:
            print(
                f"[ {Colors.RED}FAIL{Colors.NC} ] - Responded with status {Colors.RED}{response.status_code}{Colors.NC}"
            )
            return False
    except requests.exceptions.RequestException as e:
        print(
            f"[ {Colors.RED}FAIL{Colors.NC} ] - Request failed: {e.__class__.__name__}"
        )
        return False


def main():
    """
    Main function to run all health checks and report status.
    """
    print("--- BEND Service Health ---")
    all_ok = True
    for name, url in SERVICES.items():
        if not check_service(name, url):
            all_ok = False

    print("---------------------------")
    if all_ok:
        print(f"{Colors.GREEN}All key BEND services are responsive.{Colors.NC}")
        sys.exit(0)
    else:
        print(f"{Colors.RED}One or more BEND services are not healthy.{Colors.NC}")
        sys.exit(1)


if __name__ == "__main__":
    main()