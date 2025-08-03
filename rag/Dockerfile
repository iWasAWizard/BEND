FROM python:3.13-slim

WORKDIR /app

COPY rag/retriever.py ./retriever.py
COPY rag/docs ./docs
COPY shared ./shared

RUN pip install --no-cache-dir --break-system-packages fastapi uvicorn qdrant-client sentence-transformers pypdf \
    python-docx python-pptx python-json-logger python-multipart \
    opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp opentelemetry-instrumentation-fastapi

CMD ["uvicorn", "retriever:app", "--host", "0.0.0.0", "--port", "8000"]