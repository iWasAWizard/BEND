#!/usr/bin/env python
# BEND/scripts/healthcheck.py
"""
This script is intended to be run from the host machine, not inside a container.
It checks the health of all key BEND services by making HTTP requests to their health endpoints.
If any service is unresponsive or returns an error status, it will print a failure message
and exit with a non-zero status code.
"""

import os
import requests
import sys
import logging


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
    "Ollama": os.getenv("OLLAMA_URL", "http://localhost:12009/"),
    "Guardrails": os.getenv("GUARDRAILS_URL", "http://localhost:12012/health"),
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
    logger = logging.getLogger("bend.healthcheck")
    logging.basicConfig()
    logger.info("Checking %s...", f"{Colors.YELLOW}{name:<15}{Colors.NC}")
    try:
        # Increased timeout for services that might be slow to start (like vLLM)
        response = requests.get(url, timeout=20)
        if 200 <= response.status_code < 400:
            logger.info(
                "[ %sOK%s ] - Responded with status %s%s%s",
                Colors.GREEN,
                Colors.NC,
                Colors.GREEN,
                response.status_code,
                Colors.NC,
            )
            return True
        else:
            logger.error(
                "[ %sFAIL%s ] - Responded with status %s%s%s",
                Colors.RED,
                Colors.NC,
                Colors.RED,
                response.status_code,
                Colors.NC,
            )
            return False
    except requests.exceptions.RequestException as e:
        logger.error(
            "[ %sFAIL%s ] - Request failed: %s",
            Colors.RED,
            Colors.NC,
            e.__class__.__name__,
        )
        return False


def main():
    """
    Main function to run all health checks and report status.
    """
    logger = logging.getLogger("bend.healthcheck")
    logging.basicConfig()
    logger.info("--- BEND Service Health ---")
    all_ok = True
    for name, url in SERVICES.items():
        if not check_service(name, url):
            all_ok = False

    logger.info("---------------------------")
    if all_ok:
        logger.info("%sAll key BEND services are responsive.%s", Colors.GREEN, Colors.NC)
        sys.exit(0)
    else:
        logger.error("%sOne or more BEND services are not healthy.%s", Colors.RED, Colors.NC)
        sys.exit(1)


if __name__ == "__main__":
    main()
