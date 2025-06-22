```markdown
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
- **Text-to-speech** via Piper with streamlined voice management
- **Unified voice proxy API** (`/speak`, `/transcribe`)
- **Full-featured Document RAG system** (Ingest `.pdf`, `.docx`, `.pptx`, `.txt`, `.md`)
- **Optional API Key Security** for all endpoints
- **Deep Observability** via structured JSON logging and OpenTelemetry tracing
- **OpenWebUI** frontend with direct RAG integration
- **Fully Dockerized** and rebuildable from scratch

---

## 📁 Project Structure

```
bend/
├── models.yaml              # Canonical model registry
├── docker-compose.yml       # All services, one file
├── .env                     # Your local configuration
├── scripts/                 # Utility scripts
│   └── healthcheck.sh
├── models/                  # GGUF + EXL2 model files
├── audio/                   # Whisper scratchpad
├── piper/                   # Voice model volume
├── examples/
│   └── agent.py             # Example of a full RAG->LLM->TTS loop
├── rag-stack/               # RAG API + vector database
│   ├── retriever.py
│   ├── Dockerfile
│   └── docs/
└── voice-proxy/             # Voice API proxy
    ├── main.py
    └── Dockerfile
```

---

## 🛠️ Setup

### 1. Install Dependencies

```bash
brew install yq       # macOS
sudo snap install yq  # Linux
```

### 2. Clone + Configure

```bash
git clone https://github.com/yourname/bend
cd bend
# Create your .env file from the example
cp .env.example .env
```
Your `.env` file holds your custom configuration. The `switch-model.sh` script will populate `MODEL_NAME` and `MODEL_CONTEXT_SIZE` for you.

**.env.example**
```env
# Populated by scripts/switch-model.sh
MODEL_NAME=
MODEL_CONTEXT_SIZE=

# STT/TTS Configuration
WHISPER_MODEL=base.en
PIPER_VOICE=en_US-lessac-medium.onnx

# Optional: Set a secret key to protect all API endpoints
# BEND_API_KEY=your-secret-key-here

# Optional: Set an OpenTelemetry endpoint to enable tracing
# OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4317
```

### 3. (Optional) Enable GPU Support
If you have an NVIDIA GPU, uncomment the `deploy` section in the `koboldcpp` service within `docker-compose.yml` to dedicate GPU resources to the LLM.

### 4. Bootstrap the Stack

```bash
# First, select a model. This populates .env and hot-swaps if the stack is running.
./scripts/switch-model.sh hermes

# Then, bring up the stack.
docker compose up -d --build
```

---

## 📞 API Endpoints

| Endpoint            | Description                                |
|---------------------|--------------------------------------------|
| `POST /speak`       | Input text → Returns audio                 |
| `POST /transcribe`  | Input audio → Returns text                 |
| `POST /ingest`      | Upload document for RAG                    |
| `POST /ingest/text` | Ingest raw text for RAG (via JSON)         |
| `POST /retrieve`    | Query your documents                       |
| `GET /documents`    | List all ingested document sources         |
| `DELETE /documents` | Delete a document by source name (via JSON)|

---

## 🔒 API Security

If you set `BEND_API_KEY` in your `.env` file, all `retriever` and `voice-proxy` endpoints will be protected. You must include your key in the `X-API-Key` header with every request.

---

## 🔄 Scripts

| Script            | Purpose                                        |
|-------------------|------------------------------------------------|
| `switch-model.sh` | Hot-swap the LLM with no downtime              |
| `add-voice.sh`    | Download a new TTS voice for Piper             |
| `rebuild.sh`      | Tear down & rebuild full stack                 |
| `list-models.sh`  | Pretty print all model options                 |
| `healthcheck.sh`  | Check the online status of all BEND services   |

---

## 🔬 Observability (Logging & Tracing)

BEND is built for operators. All Python services (`retriever`, `voice-proxy`) emit structured JSON logs for easy collection and analysis by systems like AEGIS.

Additionally, they are instrumented with OpenTelemetry. You can enable distributed tracing by pointing them to a trace collector.

### Enabling Tracing with Jaeger

1.  Create a `docker-compose.override.yml` file in your `bend/` directory with the following content:
    ```yaml
    # docker-compose.override.yml
    version: "3.9"
    services:
      jaeger:
        image: jaegertracing/all-in-one:latest
        container_name: jaeger
        ports:
          - "16686:16686" # Jaeger UI
          - "4317:4317"   # OTLP gRPC endpoint
    ```

2.  Uncomment and set the `OTEL_EXPORTER_OTLP_ENDPOINT` in your `.env` file:
    ```env
    OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4317
    ```
3.  Restart the stack with `docker compose up -d --build`.
4.  Make some API calls and view your traces at `http://localhost:16686`.

---

## 🤖 Running the Agent Example

The `examples/agent.py` script demonstrates the full power of the BEND stack by chaining the services together to answer a question.

**To run it:**
```bash
# Make sure the stack is running first
# If you have an API key set, it will be used automatically
export BEND_API_KEY=$(grep BEND_API_KEY .env | cut -d '=' -f2)

python examples/agent.py "How do I restart the BEND stack?"
```
The script will:
1.  **Retrieve** relevant context from your documents.
2.  **Generate** a text answer using the LLM.
3.  **Speak** the answer, saving it to `response.wav`.

---

## 🧠 Model Registry (`models.yaml`)

All supported models live here. To add new ones, just extend the file:

```yaml
- key: yourmodel
  name: Your Custom Model
  filename: your-model-name.gguf
  quant: Q5_K_M
  context: 8K
  use_case: creative writing
  url: https://huggingface.co/YourUser/YourModel/resolve/main/model.gguf
```

---

## 🗣️ Managing TTS Voices

You can easily add new text-to-speech voices from the [Piper voice repository](https://huggingface.co/rhasspy/piper-voices/tree/main). Use `./scripts/add-voice.sh <voice_name>`.

---

## 🧼 Reset Everything

```bash
./rebuild.sh
```

Wipes containers, volumes, restarts with current model + endpoints.

---

## 📈 Monitoring

-   **System:** Visit `http://localhost:12005` for the Glances dashboard.
-   **Services:** Run `./scripts/healthcheck.sh` for an instant status report.

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