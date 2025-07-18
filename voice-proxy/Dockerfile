FROM python:3.13-slim

WORKDIR /app
COPY main.py .

RUN pip install --no-cache-dir --break-system-packages fastapi uvicorn httpx python-json-logger \
    opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp opentelemetry-instrumentation-fastapi \
    python-multipart

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]