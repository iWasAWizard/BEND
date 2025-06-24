FROM python:3.11-slim

WORKDIR /app

COPY retriever.py ./
COPY docs ./docs

RUN pip install --no-cache-dir fastapi uvicorn qdrant-client sentence-transformers langchain pypdf \
    python-docx python-pptx python-json-logger python-multipart \
    opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp opentelemetry-instrumentation-fastapi

CMD ["uvicorn", "retriever:app", "--host", "0.0.0.0", "--port", "8000"]