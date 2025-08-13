#!/usr/bin/env python3
# BEND/scripts/healthcheck.py
"""
This script is intended to be run from the host machine, not inside a container.
It checks the health of all key BEND services by making HTTP requests to their health endpoints.
If any service is unresponsive or returns an error status, it will print a failure message
and exit with a non-zero status code.

This version uses only Python built-in libraries and has no external dependencies.
"""

import os
import sys
import urllib.request
import urllib.error
import socket
import http.client


# --- Colors for terminal output ---
class Colors:
    GREEN = "\033[0;32m"
    RED = "\033[0;31m"
    YELLOW = "\033[1;33m"
    NC = "\033[0m"


# --- Read API Key from environment ---
# This key is required for certain BEND services.
API_KEY = os.getenv("BACKEND_API_KEY")

# --- Service Definitions ---
# The dictionary now maps a service name to a tuple:
# (URL, {set_of_acceptable_error_codes}, requires_auth_boolean)
SERVICES = {
    "Ollama": (os.getenv("OLLAMA_URL", "http://localhost:12009/"), {}, False),
    "Ollama-Vision": (
        os.getenv("OLLAMA_VISION_URL", "http://localhost:12017/"),
        {},
        False,
    ),
    "Guardrails": (
        os.getenv("GUARDRAILS_URL", "http://localhost:12012/health"),
        {404},
        False,
    ),
    "Whisper": (os.getenv("WHISPER_URL", "http://localhost:12003/health"), {}, False),
    "Piper": (os.getenv("PIPER_URL", "http://localhost:12004/"), {405}, False),
    "Retriever": (
        os.getenv("RETRIEVER_URL", "http://localhost:12007/documents"),
        {},
        True,
    ),
}


def check_service(
    name: str, url: str, acceptable_errors: set, requires_auth: bool
) -> bool:
    """
    Checks a single service using only the built-in urllib library.

    :param name: The human-readable name of the service.
    :param url: The URL endpoint to check.
    :param acceptable_errors: A set of HTTP status codes to consider as "OK".
    :param requires_auth: A boolean indicating if the service needs an API key.
    :return: True if the service is healthy, False otherwise.
    """
    print(f"Checking {Colors.YELLOW}{name:<18}{Colors.NC}...", end="", flush=True)

    headers = {}
    if requires_auth:
        if not API_KEY:
            print(
                f"[ {Colors.RED}FAIL{Colors.NC} ] - Service requires BACKEND_API_KEY, but it is not set."
            )
            return False
        headers["x-api-key"] = API_KEY

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as response:
            status = response.getcode()
            if 200 <= status < 400:
                print(
                    f"[ {Colors.GREEN}OK{Colors.NC} ] - Responded with status {Colors.GREEN}{status}{Colors.NC}"
                )
                return True
            else:
                print(
                    f"[ {Colors.RED}FAIL{Colors.NC} ] - Responded with status {Colors.RED}{status}{Colors.NC}"
                )
                return False
    except urllib.error.HTTPError as e:
        if e.code in acceptable_errors:
            print(
                f"[ {Colors.GREEN}OK{Colors.NC} ] - Responded with expected status {Colors.GREEN}{e.code}{Colors.NC}"
            )
            return True
        else:
            print(
                f"[ {Colors.RED}FAIL{Colors.NC} ] - Responded with status {Colors.RED}{e.code}{Colors.NC}"
            )
            return False
    except (
        urllib.error.URLError,
        socket.timeout,
        ConnectionResetError,
        socket.gaierror,
        http.client.RemoteDisconnected,
    ) as e:
        reason = getattr(e, "reason", e.__class__.__name__)
        print(f"[ {Colors.RED}FAIL{Colors.NC} ] - Request failed: {reason}")
        return False


def main():
    """
    Main function to run all health checks and report status.
    """
    print("--- BEND Service Health ---")
    all_ok = True
    for name, (url, acceptable_errors, requires_auth) in SERVICES.items():
        if not check_service(name, url, acceptable_errors, requires_auth):
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
