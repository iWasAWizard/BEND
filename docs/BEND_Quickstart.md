# BEND Quickstart Guide (Standalone)

Welcome! This guide will help you get the BEND intelligence stack up and running on its own. BEND is designed to be a self-contained "brainstem" for your AI applications, providing all the core services you need in one easy-to-manage package.

By the end of this guide, you will have a complete, high-performance AI backend running locally, ready to be used by any application.

## What's Inside the Box?

BEND isn't a single application; it's a curated collection of powerful, open-source services that work together. Understanding what each piece does will help you get the most out of the stack:

-   **vLLM (The Engine):** This is the high-performance server that runs your main language models. It's incredibly fast and efficient, especially on a GPU.
-   **Ollama (The Specialist):** An easy-to-use and highly performant model server that excels at running GGUF-quantized models, especially on Apple Silicon. It's the new default for CPU-based and non-NVIDIA execution.
-   **Qdrant (The Library):** A professional-grade vector database. This is the heart of the RAG system, where the knowledge from your documents is stored and searched.
-   **Redis (The Notebook):** A fast, in-memory database that provides a simple key-value store. This is used by agents to save and recall specific facts, giving them a persistent memory.
-   **Whisper & Piper (The Ears & Voice):** These services handle speech-to-text and text-to-speech, allowing your applications to listen and speak.

## Prerequisites

Before you start, you'll need to have a few things installed on your machine:

-   **Docker & Docker Compose:** For running all the containerized services.
-   **`git`:** For cloning the repository.
-   **`yq`:** A command-line YAML processor. You can usually install it with a package manager (e.g., `brew install yq` or `apt-get install yq`).
-   **(Optional) NVIDIA GPU:** If you want GPU acceleration, you'll need an NVIDIA graphics card with the appropriate drivers and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed.

## Step 1: Get the Code & Configure Authentication

First, clone the BEND repository and create your environment file.

```bash
git clone https://github.com/your-username/BEND.git
cd BEND
cp .env.example .env
```
Now, open the new `.env` file with a text editor. **If you plan to use gated models like Llama 3, you must add your Hugging Face token here.**
```dotenv
# BEND/.env
HF_TOKEN="hf_YourHuggingFaceTokenHere"
```

## Step 2: Download Your vLLM Model

Use the `download-hf-model.sh` script with the Hugging Face repository ID. This will clone the entire model repository into the `models/` directory.
```bash
# Download the Llama 3 model repository
./scripts/download-hf-model.sh "meta-llama/Meta-Llama-3-8B-Instruct"
```

## Step 3: Configure the Stack to Use Your Model

Now that the files are downloaded, run the `switch-model.sh` script. This reads `models.yaml` and sets the correct model name and parameters in your `.env` file for all services.

```bash
./scripts/switch-model.sh llama3
```

## Step 4: Start the Stack

You're now ready to launch the BEND stack. You can start the full stack or a lightweight, essential-only version.

-   **To start the FULL stack with GPU:**
    ```bash
    ./scripts/manage.sh up --gpu
    ```
-   **To start a LITE stack with only vLLM (and core services) on GPU:**
    ```bash
    ./scripts/manage.sh up --lite vllm --gpu
    ```

## Step 5: Pull and Run an Ollama Model

After the stack is running, you need to tell the Ollama service which model to download and run.

1.  **Exec into the Ollama container:**
    ```bash
    ./scripts/manage.sh exec ollama bash
    ```
2.  **Pull the model:**
    Inside the container, run:
    ```bash
    ollama pull llama3:instruct
    ```
    Ollama will download the model and make it available. You only need to do this once.

## Step 6: Verify the Installation

Once the services are running, you can verify that everything started correctly.

1.  **Run the Healthcheck:**
    ```bash
    ./scripts/manage.sh healthcheck
    ```
2.  **Explore the Web UIs:**

| Port | Service | What it's for |
| :--- | :--- | :--- |
| `http://localhost:12002` | OpenWebUI | A friendly chat interface to talk directly to your LLM. |
| `http://localhost:12005` | Glances (Full Stack Only) | A system monitoring dashboard. |

## Step 7: Interact with the API

Your BEND stack is now running and ready to receive API calls. Here are a couple of examples using `curl` to show how you can interact with the key services directly.

**1. Get a Chat Completion from vLLM (Primary Engine):**
This command sends a prompt to the vLLM service using its OpenAI-compatible endpoint.

```bash
curl http://localhost:12011/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "aegis-agent-model",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is the capital of France?"}
    ]
  }'
```

**2. Ingest and Retrieve from the RAG Service:**
First, ingest a simple text file into the RAG system.

```bash
# Create a dummy file
echo "The secret code for Project Chimera is Crimson-Echo." > ./rag/docs/secret.txt

# Ingest the file
curl -X POST -F "file=@./rag/docs/secret.txt" http://localhost:12007/ingest
```

Now, ask a question and retrieve the information.

```bash
curl http://localhost:12007/retrieve \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the code for Project Chimera?"
  }'
```

## Next Steps

To stop the stack at any time, simply run:
```bash
./scripts/manage.sh down
```