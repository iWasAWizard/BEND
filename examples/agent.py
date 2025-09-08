import requests
import os
import argparse
import json
import logging

# Define the base URL for the AEGIS API
AEGIS_URL = "http://localhost:8000"

logger = logging.getLogger(__name__)


def run_agent_task(prompt: str, preset: str, backend_profile: str):
    """
    Constructs and sends a task to the AEGIS /api/launch endpoint and logs the result.
    """
    logger.info("%s", " AEGIS Agent Task Initiated ".center(60, "="))
    logger.info("Task Prompt: %s", prompt)
    logger.info(
        "Using Preset: '%s' with Backend Profile: '%s'", preset, backend_profile
    )

    # Check for an API key in the environment (if AEGIS requires one)
    # Note: BEND uses BACKEND_API_KEY, but AEGIS itself doesn't have a top-level key.
    # This header is included for completeness if you add security to AEGIS later.
    headers = {"Content-Type": "application/json"}

    # Construct the payload according to the LaunchRequest schema
    launch_payload = {
        "task": {"prompt": prompt},
        "config": preset,
        "execution": {"backend_profile": backend_profile},
    }

    logger.info("1. Sending task to AEGIS /api/launch endpoint...")
    try:
        response = requests.post(
            f"{AEGIS_URL}/api/launch",
            data=json.dumps(launch_payload),
            headers=headers,
            timeout=600,  # Set a long timeout as the agent may take time
        )
        response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)

        result_data = response.json()
        logger.info("   - Task received and executed by AEGIS successfully.")

    except requests.exceptions.RequestException as e:
        logger.error("Could not connect to the AEGIS API: %s", e)
        return
    except json.JSONDecodeError:
        logger.error("Failed to decode JSON response from AEGIS API.")
        try:
            logger.debug("Raw Response: %s", response.text)
        except Exception as e:
            logger.debug("Failed to log raw response: %s", e)
        return

    # 2. Display the results returned by AEGIS
    logger.info("2. Displaying Final Agent Report")
    logger.info("%s", "-" * 30)
    logger.info("SUMMARY")
    logger.info("%s", result_data.get("summary", "No summary was provided."))

    logger.info("EXECUTION HISTORY")
    history = result_data.get("history", [])
    if not history:
        logger.info("No execution history was provided.")
    else:
        for i, step in enumerate(history, 1):
            logger.info("  Step %d:", i)
            logger.info("- Thought: %s", step.get("thought"))
            logger.info(
                "- Action: %s(%s)",
                step.get("tool_name"),
                json.dumps(step.get("tool_args")),
            )
            logger.info("- Observation: %s", step.get("tool_output"))

    logger.info("%s", "=" * 60)
    logger.info("%s", " AEGIS Agent Task Complete ".center(60, "="))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Run an agent task by sending a request to the AEGIS API.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "prompt", type=str, help="The question or prompt for the agent."
    )
    parser.add_argument(
        "--preset",
        type=str,
        default="default",
        help="The agent configuration preset to use (e.g., 'default', 'verified_flow').",
    )
    parser.add_argument(
        "--backend",
        type=str,
        default="bend_local",
        help="The backend profile to use from backends.yaml (e.g., 'bend_local', 'openai_gpt4').",
    )
    args = parser.parse_args()

    # Example usage from command line:
    # python examples/agent.py "What is the capital of France?" --preset default --backend openai_gpt4
    # python examples/agent.py "Create a file named 'test.txt' and write 'hello' into it."

    run_agent_task(args.prompt, args.preset, args.backend)
