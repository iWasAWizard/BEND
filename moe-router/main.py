# BEND/moe-router/main.py
import httpx
import logging
import os
import sys
import json
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse, Response
from typing import Dict, Any, List, Set

# --- Logging Setup ---
logging.basicConfig(handlers=[logging.StreamHandler(sys.stdout)], level=logging.INFO)
logging.getLogger("uvicorn.access").disabled = True
# --- End Logging Setup ---


clients = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    clients["httpx"] = httpx.AsyncClient(timeout=None)
    yield
    await clients["httpx"].aclose()


app = FastAPI(lifespan=lifespan)

# --- Service Configuration ---
SPECIALIST_URLS = {
    "REASONING": "http://ollama-reasoning:11434/v1/chat/completions",
    "AGENTIC": "http://ollama-agentic:11434/v1/chat/completions",
    "CODING": "http://ollama-coding:11434/v1/chat/completions",
}
# Map categories to the actual model names the specialists are running.
SPECIALIST_MODELS = {
    "REASONING": os.getenv("OLLAMA_REASONING_PULL_MODEL", "phi3:mini"),
    "AGENTIC": os.getenv("OLLAMA_AGENTIC_PULL_MODEL", "llama3:8b-instruct-q4_K_M"),
    "CODING": os.getenv("OLLAMA_CODING_PULL_MODEL", "codegemma:2b"),
}
DEFAULT_SPECIALIST_KEY = "REASONING"

# --- Keyword-based Routing Logic ---
CODING_KEYWORDS: Set[str] = {
    "code",
    "python",
    "javascript",
    "golang",
    "java",
    "c++",
    "rust",
    "script",
    "function",
    "class",
    "algorithm",
    "debug",
    "error",
    "test",
    "sql",
    "query",
    "database",
    "dockerfile",
    "yaml",
    "json",
    "html",
    "css",
    "react",
    "vue",
    "angular",
    "fastapi",
    "flask",
    "django",
    "numpy",
    "pandas",
    "tensorflow",
    "pytorch",
    "calculate",
    "math",
    "equation",
}

AGENTIC_KEYWORDS: Set[str] = {
    "tool",
    "agent",
    "plan",
    "execute",
    "task",
    "goal",
    "RAG",
    "retrieve",
    "ingest",
    "document",
    "read file",
    "write file",
    "list files",
    "file system",
    "browse",
    "search",
}


def get_last_user_prompt(payload: Dict[str, Any]) -> str:
    """Extracts the content of the last message with role 'user' from the payload."""
    messages = payload.get("messages", [])
    for message in reversed(messages):
        if message.get("role") == "user":
            return message.get("content", "")
    return ""


def classify_by_keywords(prompt: str) -> str:
    """Classifies the prompt based on keyword matching."""
    prompt_lower = prompt.lower()
    # Check for coding keywords first as they can be more specific
    if any(keyword in prompt_lower for keyword in CODING_KEYWORDS):
        return "CODING"
    # Then check for agentic keywords
    if any(keyword in prompt_lower for keyword in AGENTIC_KEYWORDS):
        return "AGENTIC"
    # Default to reasoning
    return "REASONING"


@app.post("/v1/chat/completions")
async def route_chat_request(request: Request):
    """
    Receives a standard OpenAI-compatible chat request, classifies it using keywords,
    and forwards it to the appropriate specialist LLM.
    """
    raw_body = await request.body()
    payload: Dict[str, Any] = json.loads(raw_body)
    user_prompt = get_last_user_prompt(payload)

    if not user_prompt:
        logging.warning(
            "Request payload contains no user prompt. Forwarding to default specialist."
        )
        target_key = DEFAULT_SPECIALIST_KEY
    else:
        # 1. Classify the prompt using keywords
        target_key = classify_by_keywords(user_prompt)
        logging.info(f"Classified request as '{target_key}'. Routing accordingly.")

    # 2. Select the target URL and the correct downstream model name
    target_url = SPECIALIST_URLS[target_key]
    target_model = SPECIALIST_MODELS[target_key]
    logging.info(f"Forwarding request to: {target_url} with model {target_model}")

    # 3. Modify the payload to use the correct model name.
    payload["model"] = target_model

    # 4. Forward the corrected request
    is_streaming = payload.get("stream", False)
    modified_body = json.dumps(payload).encode("utf-8")
    downstream_headers = {"Content-Type": "application/json"}

    async def stream_forwarder():
        """Generator function to stream the response from the specialist."""
        async with clients["httpx"].stream(
            "POST", target_url, content=modified_body, headers=downstream_headers
        ) as r:
            r.raise_for_status()
            async for chunk in r.aiter_bytes():
                yield chunk

    if is_streaming:
        return StreamingResponse(
            stream_forwarder(),
            media_type=request.headers.get("accept", "application/x-ndjson"),
        )
    else:
        response = await clients["httpx"].post(
            target_url, content=modified_body, headers=downstream_headers
        )
        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=dict(response.headers),
        )
