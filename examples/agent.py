import requests
import os
import argparse
import json

# Define the base URL for the AEGIS API
AEGIS_URL = "http://localhost:8000"


def run_agent_task(prompt: str, preset: str, backend_profile: str):
    """
    Constructs and sends a task to the AEGIS /api/launch endpoint and prints the result.
    """
    print(" AEGIS Agent Task Initiated ".center(60, "="))
    print(f"Task Prompt: {prompt}")
    print(f"Using Preset: '{preset}' with Backend Profile: '{backend_profile}'\n")

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

    print("1. Sending task to AEGIS /api/launch endpoint...")
    try:
        response = requests.post(
            f"{AEGIS_URL}/api/launch",
            data=json.dumps(launch_payload),
            headers=headers,
            timeout=600,  # Set a long timeout as the agent may take time
        )
        response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)

        result_data = response.json()
        print("   - Task received and executed by AEGIS successfully.")

    except requests.exceptions.RequestException as e:
        print(f"\n[ERROR] Could not connect to the AEGIS API: {e}")
        return
    except json.JSONDecodeError:
        print(f"\n[ERROR] Failed to decode JSON response from AEGIS API.")
        print(f"Raw Response: {response.text}")
        return

    # 2. Display the results returned by AEGIS
    print("\n2. Displaying Final Agent Report")
    print("-" * 30)
    print("\n[SUMMARY]")
    print(result_data.get("summary", "No summary was provided."))

    print("\n[EXECUTION HISTORY]")
    history = result_data.get("history", [])
    if not history:
        print("No execution history was provided.")
    else:
        for i, step in enumerate(history, 1):
            print(f"  Step {i}:")
            print(f"    - Thought: {step.get('thought')}")
            print(
                f"    - Action: {step.get('tool_name')}({json.dumps(step.get('tool_args'))})"
            )
            print(f"    - Observation: {step.get('tool_output')}")

    print("=" * 60)
    print(" AEGIS Agent Task Complete ".center(60, "="))


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
