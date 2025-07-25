# BEND Quickstart Guide (Standalone)

Welcome! This guide will help you get the BEND intelligence stack up and running on its own. BEND is designed to be a self-contained "brainstem" for your AI applications, providing all the core services you need in one easy-to-manage package.

By the end of this guide, you will have a complete, high-performance AI backend running locally, ready to be used by any application.

## What's Inside the Box?

BEND isn't a single application; it's a curated collection of powerful, open-source services that work together. Understanding what each piece does will help you get the most out of the stack:

-   **vLLM (The Engine):** This is the high-performance server that runs your main language models. It's incredibly fast and efficient, especially on a GPU.
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

## Step 2: Download Your Models

The next step is to download the models you want to use. We have separate scripts for downloading full-repository models (for vLLM) and single-file GGUF models (for KoboldCPP).

1.  **Download the vLLM Model:**
    Use the `download-hf-model.sh` script with the Hugging Face repository ID.
    ```bash
    # Download the Llama 3 model repository
    ./scripts/download-hf-model.sh "meta-llama/Meta-Llama-3-8B-Instruct"
    ```

2.  **Download the KoboldCPP Model:**
    Use the `download-gguf-model.sh` script with the `key` from `models.yaml`.
    ```bash
    # Download the GGUF version of Llama 3
    ./scripts/download-gguf-model.sh llama3
    ```

## Step 3: Configure the Stack to Use Your Model

Now that the files are downloaded, run the `switch-model.sh` script. This reads `models.yaml` and sets the correct model names and parameters in your `.env` file for all services.

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

## Step 5: Verify the Installation

Once the services are running, you can verify that everything started correctly.

1.  **Run the Healthcheck:**
    The easiest way is to use the built-in healthcheck script.
    ```bash
    ./scripts/manage.sh healthcheck
    ```
    You should see a list of services with a green `[ OK ]` status next to each one.

2.  **Explore the Web UIs:**
    BEND comes with several web interfaces that you can access in your browser:

| Port | Service | What it's for |
| :--- | :--- | :--- |
| `http://localhost:12002` | OpenWebUI (Full Stack Only) | A friendly chat interface to talk directly to your LLM. |
| `http://localhost:12015` | MinIO Console (Full Stack Only) | The web UI for the S3 blob storage. |
| `http://localhost:12005` | Glances (Full Stack Only) | A system monitoring dashboard. |

## Next Steps

You now have a complete, high-performance AI backend running locally! To stop the stack at any time, simply run:
```bash
./scripts/manage.sh down
```