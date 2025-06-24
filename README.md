# BEND
**Backend Enhanced Neural Dispatch**

BEND is a locally-hosted, containerized intelligence stack built to run high-performance LLMs, whispering STT, cloned TTS, and full RAG pipelines.
It’s for when you want a fast, self-sufficient brainstem that does more than just answer questions—it listens, speaks, remembers, and swaps personalities on command.

> It's like ChatGPT moved into your server closet and brought a filing cabinet.

---

## 🚀 Features

- **KoboldCPP** backend (GGUF & EXL2 models)
- **Dynamic Hot-Swapping** of LLMs with zero downtime
- **Speech-to-text** via Whisper
- **Text-to-speech** via Piper
- **Unified voice proxy API** (`/speak`, `/transcribe`)
- **Document RAG system** (Ingest `.pdf`, `.docx`, `.pptx`, `.txt`, `.md`)
- **OpenWebUI** frontend
- **Fully Dockerized** and rebuildable from scratch
- **Deep Observability** via structured JSON logging and OpenTelemetry tracing
- **Optional NVIDIA GPU Acceleration** for `koboldcpp`, `whisper`, and `retriever`.

---

## 🎛️ Standalone Usage

BEND is a fully independent backend stack. All management is handled via the `scripts/manage.sh` script from the BEND project root.

### 1. Prerequisites

- Docker and Docker Compose
- `yq` (e.g., `brew install yq`)
- A downloaded GGUF model file.
- For GPU support: NVIDIA GPU with drivers and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed.

### 2. Setup

```bash
# Place your downloaded .gguf file inside the models/ directory
mv ~/Downloads/Nous-Hermes-2-Mixtral-8x7B.Q5_K_M.gguf ./models/

# Select the model to use. This creates the .env file needed to start.
./scripts/switch-model.sh hermes
```
> **Note on Gated Models:** To download models that require authentication from Hugging Face, edit the newly created `.env` file and add your Hugging Face Read Token to the `HF_TOKEN` variable. This token will be used by the `airgap-bundle` command.

### 3. Manage the Stack

- **Start BEND (CPU):** `./scripts/manage.sh up`
- **Start BEND (NVIDIA GPU):** `./scripts/manage.sh up --gpu`
- **Stop BEND:** `./scripts/manage.sh down`
- **Check Status:** `./scripts/manage.sh status`
- **View Logs:** `./scripts/manage.sh logs` or `./scripts/manage.sh logs koboldcpp`
- **Switch LLM:** `./scripts/manage.sh switch mythomax`

#### GPU Configuration
After running `switch-model.sh`, you can edit the `.env` file to control how many layers are offloaded to the GPU:
- `KOBOLD_GPU_LAYERS=99` (A high number means "offload as many as possible")
- `WHISPER_GPU_LAYERS=99`

---

## 📁 Project Structure

```
bend/
├── models.yaml              # Canonical model registry
├── docker-compose.yml       # All services, one file
├── .env                     # Auto-generated model link
├── scripts/                 # Utility & Management scripts
│   ├── manage.sh
│   ├── switch-model.sh
│   └── healthcheck.sh
├── models/                  # GGUF + EXL2 model files
├── rag/                     # RAG API + vector database
└── voice-proxy/             # Voice API proxy
```

---

## 🎯 Ports

| Port   | Service      |
|--------|--------------|
| 12002  | OpenWebUI    |
| 12003  | Whisper STT  |
| 12004  | Piper TTS    |
| 12005  | Glances      |
| 12006  | Qdrant (RAG) |
| 12007  | Retriever API|
| 12008  | Voice Proxy  |
| 12009  | KoboldCPP    |
<<<<<<< HEAD
=======

---

## 💬 Philosophy

BEND is designed to be:
- **Modular** – swap pieces in/out
- **Reproducible** – bootstrap cleanly, rebuild reliably
- **Self-hosted** – no cloud, no SaaS, just horsepower
- **Expandable** – perfect core for agent stacks like AEGIS

---

## 🧪 Status

BEND is stable and deployable. It is also:
- Curious
- Loud
- Excellent at solving your problems and/or creating new ones

> “You don’t build a backend like this for fun.
> You build it because **you want the machine to talk back.**”
```

>>>>>>> 0aa86007981b2a92ed1a61d3f5e1e0d777b7f122
