Of course. You're right, adding more mass and detail to these key documents will make them much more valuable. Let's flesh them out, one at a time, starting with the **BEND Quickstart Guide**.

I will expand each section to provide more context, explain the *why* behind the commands, and add a new section to give users a better mental model of what they're running. The tone will remain helpful and easygoing.

---

# BEND Quickstart Guide (Standalone)

Welcome! This guide will help you get the BEND intelligence stack up and running on its own. BEND is designed to be a self-contained "brainstem" for your AI applications, providing all the core services you need in one easy-to-manage package.

By the end of this guide, you will have a complete, high-performance AI backend running locally, ready to be used by any application.

## What's Inside the Box?

BEND isn't a single application; it's a curated collection of powerful, open-source services that work together. Understanding what each piece does will help you get the most out of the stack:

-   **vLLM (The Engine):** This is the high-performance server that runs your main language models. It's incredibly fast and efficient, especially on a GPU.
-   **LangFuse (The Flight Recorder):** An observability platform that gives you a beautiful web UI to trace every thought and action your AI takes. It's essential for debugging.
-   **Qdrant (The Library):** A professional-grade vector database. This is the heart of the RAG system, where the knowledge from your documents is stored and searched.
-   **Redis (The Notebook):** A fast, in-memory database that provides a simple key-value store. This is used by agents to save and recall specific facts, giving them a persistent memory.
-   **Whisper & Piper (The Ears & Voice):** These services handle speech-to-text and text-to-speech, allowing your applications to listen and speak.
-   **KoboldCPP (The Specialist):** While vLLM is the primary engine, KoboldCPP is an excellent fallback that specializes in running GGUF-quantized models, giving you access to a huge ecosystem of community-tuned models.

## Prerequisites

Before you start, you'll need to have a few things installed on your machine:

-   **Docker & Docker Compose:** For running all the containerized services.
-   **`git`:** For cloning the repository.
-   **`yq`:** A command-line YAML processor. You can usually install it with a package manager (e.g., `brew install yq` or `apt-get install yq`).
-   **(Optional) NVIDIA GPU:** If you want GPU acceleration, you'll need an NVIDIA graphics card with the appropriate drivers and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed.

## Step 1: Get the Code

First, clone the BEND repository to your local machine and navigate into the directory.

```bash
git clone https://github.com/your-username/BEND.git
cd BEND
```

## Step 2: Choose and Download a Model

BEND needs to know which language model you want to run. The available models are defined in `models.yaml`.

1.  **List Available Models:**
    You can see a list of pre-configured models and their use cases by running:
    ```bash
    ./scripts/list-models.sh
    ```

2.  **Download the GGUF Model Files:**
    While vLLM will automatically download models from Hugging Face, the KoboldCPP service needs a local GGUF file. It's best to download the one you plan to use. The script makes this easy. For example, to download the `llama3` model:
    ```bash
    ./scripts/download-model.sh llama3
    ```
    This will download the correct `.gguf` file and place it in the `models/` directory, making it available to the KoboldCPP container.

## Step 3: Configure Your Environment

The `switch-model.sh` script is the main way to configure your stack. It intelligently creates or edits a `.env` file with the correct settings for the model you choose. This file is the central source of truth for the Docker Compose setup.

To configure the stack to use the `llama3` model you just downloaded, run:

```bash
./scripts/switch-model.sh llama3
```

This command sets the `MODEL_NAME` (for vLLM) and `KOBOLDCPP_MODEL_NAME` (for KoboldCPP) variables in the `.env` file. If the `.env` file already exists, this script will safely update these values while preserving any other keys you may have added (like API keys).

**Pro Tip:** If you need to download a gated model from Hugging Face, you can add your token to the `.env` file like this: `HF_TOKEN=hf_...`. The vLLM service will automatically use it.

## Step 4: Start the Stack

You're now ready to launch the entire BEND stack. This command reads the `docker-compose.yml` file and your `.env` file to start all the services.

-   **For CPU-only:**
    ```bash
    ./scripts/manage.sh up
    ```-   **For NVIDIA GPU acceleration:**
    ```bash
    ./scripts/manage.sh up --gpu
    ```

The first time you run this, it will build the custom Docker images and may take several minutes. Subsequent starts will be much faster.

## Step 5: Verify the Installation

Once the services are running, you can verify that everything started correctly.

1.  **Run the Healthcheck:**
    The easiest way is to use the built-in healthcheck script.
    ```bash
    ./scripts/manage.sh healthcheck
    ```
    You should see a list of services with a green `[ OK ]` status next to each one. vLLM can sometimes take a minute or two to download its model and become healthy, so if it fails at first, wait a moment and try again.

2.  **Explore the Web UIs:**
    BEND comes with several web interfaces that you can access in your browser:

| Port | Service | What it's for |
| :--- | :--- | :--- |
| `http://localhost:12002` | OpenWebUI | A friendly chat interface to talk directly to your LLM. It's pre-configured to connect to the vLLM service. |
| `http://localhost:12012` | LangFuse | The observability platform. After you run an agent, this is where you'll see a detailed, visual trace of its activity. |
| `http://localhost:12005` | Glances | A system monitoring dashboard to see the real-time CPU, GPU, and RAM usage of all the services. |

## Step 6: Interact with the API

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

You now have a complete, high-performance AI backend running locally! From here, you can start building your own applications against its APIs or proceed to the **AEGIS Quickstart Guide** to connect an autonomous agent to it.

To stop the stack at any time, simply run:
```bash
./scripts/manage.sh down
```