# BEND/moe-router/Dockerfile
FROM python:3.13-slim

WORKDIR /app

COPY moe-router/main.py ./main.py

RUN pip install --no-cache-dir --break-system-packages \
    fastapi \
    uvicorn \
    httpx

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]