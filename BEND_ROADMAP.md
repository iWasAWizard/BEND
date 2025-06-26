# 🧠 BEND: Feature Roadmap

This document outlines the strategic development roadmap for the BEND (Backend Enhanced Neural Dispatch) stack. These features are designed to evolve BEND from a simple AI backend into a comprehensive, self-improving, and highly immersive intelligence platform.

---

## Tier 1: Core Experience & Immersion

*These features are the highest priority and directly enhance the core user experience for interactive applications.*

### **1. Vector-Based Conversational Memory (The "Chronicler")**

*   **Description:** A dedicated service for creating a persistent, long-term memory of conversations. It will automatically take conversation snippets, summarize them, and store them as vectors for fast, semantic retrieval.
*   **Why It Matters:** This solves the "goldfish memory" problem. It allows the agent or character to recall past interactions, promises, and key facts from previous conversations, providing a seamless and continuous narrative experience. It's the foundation of a believable, persistent personality.
*   **Implementation Sketch:**
    1.  Extend the existing `retriever` service with a new Qdrant collection (e.g., `conversation_memory`).
    2.  Add a `/commit-memory` endpoint that accepts text, generates an embedding, and stores it.
    3.  Add a `/recall-memory` endpoint that takes a query, performs a vector search on the conversation memory, and returns the most relevant past snippets.

### **2. TTS Voice Cloning Service (The "Mimic")**

*   **Description:** A service that can take a short audio sample (a few seconds) of a voice and generate a new, high-quality TTS voice model that can be used immediately.
*   **Why It Matters:** This offers ultimate personalization. Users can clone their own voice or create unique voices for different characters, moving beyond a small set of pre-canned options and dramatically increasing immersion.
*   **Implementation Sketch:**
    1.  Add a new Docker service running a state-of-the-art voice cloning tool like [XTTSv2](https://github.com/coqui-ai/TTS).
    2.  Create a `/clone-voice` endpoint that accepts an audio file and saves the resulting voice model to a shared volume.
    3.  Update the `piper` TTS service to be able to load and use these newly generated models on the fly.

---

## Tier 2: Architectural & Systemic Enhancements

*These features improve the underlying architecture of BEND, making it more robust, scalable, and capable of more complex, asynchronous tasks.*

### **3. World Info & Lorebook Service (The "Librarian")**

*   **Description:** A centralized backend service for managing structured "world knowledge" (lore, character sheets, location data). This service will intelligently pre-process user prompts, semantically searching the lorebook and injecting only the most relevant context before sending the prompt to the main LLM.
*   **Why It Matters:** This is a more intelligent form of RAG. It ensures the LLM has the necessary world knowledge without bloating the context window with irrelevant information. By centralizing this service in BEND, the world knowledge becomes a consistent part of the "brain," accessible to any client application (AEGIS, OpenWebUI, etc.).
*   **Implementation Sketch:**
    1.  Add a CRUD API to the `retriever` service for managing lorebook entries.
    2.  Create a new endpoint (e.g., `/enrich-prompt`) that performs a hybrid keyword/vector search on the lorebook based on the prompt's content.
    3.  Use a cheap LLM call to prune the search results down to the most relevant snippets before returning the final, enriched prompt.

### **4. Real-time Event Bus (The "Nervous System")**

*   **Description:** Integrate a lightweight message queue (like NATS or Redis Pub/Sub) as the central communication backbone for BEND services.
*   **Why It Matters:** This decouples the services, making the system more resilient and scalable. It's the foundation for enabling complex, asynchronous workflows (e.g., "analyze this large document and notify me when you're done") and is the primary prerequisite for future multi-agent communication.
*   **Implementation Sketch:**
    1.  Add a NATS or Redis service to `docker-compose.yml`.
    2.  Refactor internal service communication (e.g., from `voice-proxy` to `whisper`) to publish and subscribe to events on the bus instead of using direct HTTP calls.

---

## Deferred for Future Development

*These features represent powerful, long-term goals for the project. They are deferred for now due to their high implementation complexity.*

*   **Code Execution Sandbox (The "Isolated Lab"):** A secure, containerized environment for the agent to write and execute arbitrary code. This is a massive step in agent capability but requires careful security considerations.
*   **Automated Fine-Tuning Pipeline (The "Trainer"):** A full MLOps pipeline to automatically fine-tune the core LLM on successful interactions, allowing the system to improve itself over time.
