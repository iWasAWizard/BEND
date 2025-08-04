# BEND
**BackEND**

[![Docker](https://img.shields.io/badge/containerized-Docker-blue)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

BEND is a locally-hosted, containerized backend stack designed to give your AI applications a solid foundation. It bundles together a suite of high-performance, open-source services for language models, document retrieval (RAG), voice, and more.

Think of it as a ready-to-run "AI power source" for your projects, letting you focus on building your application instead of managing complex infrastructure.

---

## What's in the Box? A Tour of the Services

BEND isn't a single application; it's a curated collection of services that work together seamlessly. Here’s a quick look at the key components and the role each one plays:

-   **MoE Router (The Dispatcher):** The new primary endpoint for all LLM requests. This service uses simple keyword matching to classify incoming prompts and route them to the appropriate specialist model.
-   **Ollama (The Specialists):** BEND now runs multiple, independent Ollama instances, each serving a specific Small Language Model (SLM) tailored for a particular task (e.g., reasoning, coding, agentic actions).
-   **Qdrant (The Library):** A professional-grade vector database. This is the heart of the RAG system, where the knowledge from your documents is stored, indexed, and made searchable.
-   **Redis (The Notebook):** A fast, in-memory database that provides a simple key-value store. This is used by agents to save and recall specific facts, giving them a persistent long-term memory.
-   **NeMo Guardrails (The Safety Inspector):** A security layer that can inspect an agent's proposed actions and block them if they violate pre-defined safety rules, preventing dangerous or unintended behavior.
-   **Whisper & Piper (The Ears & Voice):** These services handle speech-to-text and text-to-speech, allowing your applications to listen and speak through a simple, unified API.

## Architecture

All services run in their own Docker containers and communicate over a private network called `bend_bend-net`. The core of the new architecture is a lightweight Mixture-of-Experts (MoE) setup where a central router distributes tasks to specialized models.

```
+-------------------------------------------------------------------------+
| BEND Docker Environment (Network: bend_bend-net)                        |
|                                                                         |
|      +------------+        +-------------------+                        |
|      | AEGIS /    | -----> |    MoE Router     |                        |
|      | other apps |        | (Port 12016)      |                        |
|      +------------+        | (Keyword Logic)   |                        |
|                            +-------------------+                        |
|                                |      |      |                          |
|              +-----------------+      |      +-----------------+        |
|              |                        |                        |        |
|              v                        v                        v        |
|  +----------------------+  +----------------------+  +----------------------+
|  |  Ollama (Reasoning)  |  |   Ollama (Agentic)   |  |    Ollama (Coding)   |
|  |  (Phi-3 Mini)        |  |   (Llama 3 8B)       |  |   (Codegemma 2B)     |
|  +----------------------+  +----------------------+  +----------------------+
|                                                                         |
+-------------------------------------------------------------------------+
```

## 🚀 Quickstart

### 1. Prerequisites

-   Docker & Docker Compose
-   `git`
-   `yq` (e.g., `brew install yq` or `apt-get install yq`)
-   **(Optional) NVIDIA GPU** with the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

### 2. Setup

First, clone the repository and create your environment file. No authentication tokens are required for this setup.

```bash
git clone https://github.com/your-username/BEND.git
cd BEND
cp .env.example .env
```

Now, open the new `.env` file and add the following lines.
```dotenv
# BEND/.env
# Pull names are public models from the main Ollama Hub.
OLLAMA_REASONING_PULL_MODEL="phi3:mini"
OLLAMA_AGENTIC_PULL_MODEL="llama3:8b-instruct-q4_K_M"
OLLAMA_CODING_PULL_MODEL="codegemma:2b"
```

### 3. Start the Stack

You're now ready to launch all the BEND services.

-   **For CPU-only:**
    ```bash
    ./scripts/manage.sh up
    ```
-   **For NVIDIA GPU acceleration (recommended):**
    ```bash
    ./scripts/manage.sh up --gpu
    ```

### 4. Verify the Installation

Use the built-in healthcheck to make sure all services started correctly. It may take a minute for the Ollama services to download their models and become healthy.

```bash
./scripts/manage.sh healthcheck
```

Once all services show `[ OK ]`, you can explore the web interfaces for OpenWebUI (`http://localhost:12002`), which is connected to the reasoning model.

## ⚙️ Management

All stack management is handled by the `manage.sh` script:

-   `./scripts/manage.sh up`: Start all services.
-   `./scripts/manage.sh down`: Stop all services.
-   `./scripts/manage.sh restart [service_name]`: Restart all services or a specific one.
-   `./scripts/manage.sh logs [service_name]`: Tail the logs for all services or a specific one (e.g., `redis`).
-   `./scripts/manage.sh status`: Show the status of all running containers.
-   `./scripts/manage.sh rebuild`: Force a rebuild of the Docker images without using the cache.

## 🎯 Ports Reference

| Port   | Service                   | Notes                                         |
|--------|---------------------------|-----------------------------------------------|
| 12002  | OpenWebUI                 | UI for the Reasoning model                    |
| 12003  | Whisper STT               | Speech-to-Text API                            |
| 12004  | Piper TTS                 | Text-to-Speech API                            |
| 12005  | Glances                   | System Monitoring                             |
| 12006  | Qdrant (RAG)              | Vector Database                               |
| 12007  | Retriever API             | RAG Ingestion API                             |
| 12008  | Voice Proxy               | Unified Voice API                             |
| 12009  | Ollama (Reasoning)        | Specialist for Reasoning (Phi-3 Mini)         |
| 12010  | Redis                     | Agent Memory                                  |
| 12012  | NeMo Guardrails           | Safety Layer                                  |
| 12013  | Ollama (Agentic)          | Specialist for Agent/RAG (Llama 3 8B)         |
| 12014  | Ollama (Coding)           | Specialist for Code/Math (Codegemma 2B)       |
| 12016  | MoE Router                | Primary endpoint for all LLM queries.         |


## 🤝 Connecting with AEGIS

BEND is designed to be the perfect backend for the **AEGIS** agentic framework. To connect AEGIS to this new MoE stack, you would update the `llm_url` in your AEGIS `backends.yaml` to point to the MoE Router's endpoint: `http://localhost:12016/v1`.

## 💬 Philosophy

BEND is designed to be:

-   **Modular:** Swap pieces in and out as you need.
-   **Reproducible:** Builds reliably from a clean state, every time.
-   **Self-hosted:** Runs on your own hardware, with no cloud dependencies.
-   **Expandable:** Serves as a great foundation for building your own AI-powered applications.
