import requests
import os
import argparse

# Define the base URLs for the BEND services
RETRIEVER_URL = "http://localhost:12007"
KOBOLD_URL = "http://localhost:12009"
VOICE_URL = "http://localhost:12008"
OUTPUT_FILENAME = "response.wav"


def run_agent_loop(query: str):
    """
    Executes a full RAG -> LLM -> TTS loop using the BEND stack.
    """
    print(" BEND Agent Loop Initialized ".center(60, "="))
    print(f"User Query: {query}\n")

    # Check for an API key in the environment
    api_key = os.getenv("BEND_API_KEY")
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["X-API-Key"] = api_key
        print("...API key found and will be used for requests.")

    # 1. Retrieve context using the RAG service
    try:
        print("1. Retrieving context from RAG service...")
        rag_payload = {"query": query, "top_k": 3}
        rag_response = requests.post(
            f"{RETRIEVER_URL}/retrieve", json=rag_payload, headers=headers
        )
        rag_response.raise_for_status()
        context_items = rag_response.json()
        if not context_items:
            print("   - No relevant context found.")
            context = "No context found."
        else:
            context_chunks = [
                f"Source: {item['source']}\n{item['text']}" for item in context_items
            ]
            context = "\n---\n".join(context_chunks)
            print(f"   - Found {len(context_items)} context chunks.")

    except requests.RequestException as e:
        print(f"\n[ERROR] Could not connect to the Retriever service: {e}")
        return

    # 2. Generate a response using the LLM
    try:
        print("\n2. Generating response with LLM...")
        prompt = (
            "You are a helpful assistant. Use the following context to answer the user's question. "
            "If the context is not relevant, answer the question based on your own knowledge.\n\n"
            f"--- CONTEXT ---\n{context}\n\n"
            f"--- QUESTION ---\n{query}\n\n"
            "--- ANSWER ---\n"
        )

        # KoboldCPP's /api/v1/generate endpoint
        llm_payload = {
            "prompt": prompt,
            "max_context_length": 8192,
            "max_length": 300,
            "temperature": 0.7,
            "top_p": 0.9,
            "stop_sequence": ["\n---", "User:"],
        }
        llm_response = requests.post(f"{KOBOLD_URL}/api/v1/generate", json=llm_payload)
        llm_response.raise_for_status()
        llm_text = llm_response.json()["results"][0]["text"].strip()
        print(f"   - LLM Response: {llm_text}")

    except requests.RequestException as e:
        print(f"\n[ERROR] Could not connect to the KoboldCPP service: {e}")
        return

    # 3. Synthesize the response into speech
    try:
        print("\n3. Synthesizing audio with TTS service...")
        speak_payload = {"text": llm_text}
        speak_response = requests.post(
            f"{VOICE_URL}/speak", json=speak_payload, headers=headers
        )
        speak_response.raise_for_status()

        with open(OUTPUT_FILENAME, "wb") as f:
            f.write(speak_response.content)
        print(f"   - Success! Audio saved to '{OUTPUT_FILENAME}'")

    except requests.RequestException as e:
        print(f"\n[ERROR] Could not connect to the Voice Proxy service: {e}")
        return

    print("=" * 60)
    print(" BEND Agent Loop Complete ".center(60, "="))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Run a full agent loop using the BEND stack (RAG -> LLM -> TTS).",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("query", type=str, help="The question or prompt for the agent.")
    args = parser.parse_args()

    # Example usage:
    # python examples/agent.py "How do I restart the stack?"
    # BEND_API_KEY=my-secret-key python examples/agent.py "How do I switch models?"

    run_agent_loop(args.query)
