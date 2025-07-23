# BEND
**Backend Enhanced Neural Dispatch**

BEND is a locally-hosted, containerized backend stack designed to give your AI applications a solid foundation. It bundles together high-performance services for language models, document retrieval (RAG), voice, and more.

Think of it as a ready-to-run power source for your AI projects, letting you focus on building your application instead of managing infrastructure.

> It's like ChatGPT moved into your server closet and brought a filing cabinet.

---

## 🚀 Features

- **High-Performance LLM Serving:** Comes with vLLM for top-tier speed and KoboldCPP for broad model compatibility.
- **Full Observability:** Includes LangFuse to give you a clear, visual trace of your AI's thoughts and actions.
- **Safety Ready:** An optional NeMo Guardrails service is included to help you build safer agents.
- **Agent Memory:** A built-in Redis service provides a fast and reliable key-value store for long-term agent memory.
- **Document Retrieval (RAG):** A complete RAG pipeline with Qdrant lets your applications pull information from your own documents.
- **Voice Capabilities:** Includes Whisper for speech-to-text and Piper for text-to-speech, all accessible through a single API.
- **Web UI Included:** Comes with OpenWebUI for chatting directly with your models.
- **Fully Dockerized:** The entire stack is managed with Docker Compose, making setup and teardown simple.
- **GPU Accelerated:** Provides optional NVIDIA GPU support for all the key services.

---

## 🎛️ Standalone Usage

BEND is a fully independent backend stack. All management is handled via the `scripts/manage.sh` script from the BEND project root.

### 1. Prerequisites

- Docker and Docker Compose
- `yq` (e.g., `brew install yq`)
- A downloaded GGUF or Hugging Face model file.
- For GPU support: NVIDIA GPU with drivers and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed.

### 2. Setup

```bash
# Place your downloaded model files inside the models/ directory.
# This directory is mounted into both vLLM and KoboldCPP.

# Create the .env file needed to start.
./scripts/switch-model.sh hermes
```
> **Note on Gated Models:** To download models that require authentication from Hugging Face, edit the newly created `.env` file and add your Hugging Face Read Token to the `HF_TOKEN` variable. This token will be used by the `airgap-bundle` command.

### 3. Manage the Stack

- **Start BEND (CPU):** `./scripts/manage.sh up`
- **Start BEND (NVIDIA GPU):** `./scripts/manage.sh up --gpu`
- **Stop BEND:** `./scripts/manage.sh down`
- **Check Status:** `./scripts/manage.sh status`
- **View Logs:** `./scripts/manage.sh logs` or `./scripts/manage.sh logs vllm`
- **Switch LLM:** `./scripts/manage.sh switch mythomax`

---

## 📁 Project Structure

```bend/
├── models.yaml              # Canonical model registry
├── docker-compose.yml       # All services, one file
├── .env                     # Auto-generated model link
├── scripts/                 # Utility & Management scripts
├── guardrails/              # NeMo Guardrails configuration
├── models/                  # GGUF + HF model files
├── rag/                     # RAG API + vector database
└── voice-proxy/             # Voice API proxy
```

---

## 🎯 Ports

| Port   | Service          |
|--------|------------------|
| 12002  | OpenWebUI        |
| 12003  | Whisper STT      |
| 12004  | Piper TTS        |
| 12005  | Glances          |
| 12006  | Qdrant (RAG)     |
| 12007  | Retriever API    |
| 12008  | Voice Proxy      |
| 12009  | KoboldCPP        |
| 12010  | Redis            |
| 12011  | vLLM             |
| 12012  | LangFuse         |
| 12013  | NeMo Guardrails  |

---

## 💬 Philosophy

BEND is designed to be:
- **Modular** – Swap pieces in and out as you need.
- **Reproducible** – Rebuilds reliably from a clean state.
- **Self-hosted** – Runs on your own hardware, with no cloud dependencies.
- **Expandable** – Serves as a great foundation for agentic frameworks like AEGIS.