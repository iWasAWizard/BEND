FROM python:3.11-slim

WORKDIR /app
COPY main.py .

RUN pip install --no-cache-dir fastapi uvicorn httpx python-json-logger \
    opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp opentelemetry-instrumentation-fastapi

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]