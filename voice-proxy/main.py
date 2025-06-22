import logging
import sys
from pythonjsonlogger import jsonlogger

import os
from contextlib import asynccontextmanager
import httpx

from fastapi import FastAPI, UploadFile, File, Response, HTTPException, Depends, Header
from pydantic import BaseModel

# OpenTelemetry Imports
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# --- Logging Setup ---
logHandler = logging.StreamHandler(sys.stdout)
formatter = jsonlogger.JsonFormatter(
    fmt="%(asctime)s %(name)s %(levelname)s %(message)s"
)
logHandler.setFormatter(formatter)
logging.basicConfig(handlers=[logHandler], level=logging.INFO)
logging.getLogger("uvicorn.access").disabled = True
# --- End Logging Setup ---

# --- Tracing Setup ---
API_KEY = os.getenv("BEND_API_KEY")
OTEL_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
clients = {}

if OTEL_ENDPOINT:
    provider = TracerProvider()
    processor = BatchSpanProcessor(
        OTLPSpanExporter(endpoint=OTEL_ENDPOINT, insecure=True)
    )
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)
    tracer = trace.get_tracer(__name__)
else:
    tracer = None
# --- End Tracing Setup ---


@asynccontextmanager
async def lifespan(app: FastAPI):
    clients["httpx"] = httpx.AsyncClient()
    yield
    await clients["httpx"].aclose()


async def api_key_security(x_api_key: str = Header(None)):
    if API_KEY:  # Security is enabled
        if x_api_key != API_KEY:
            raise HTTPException(status_code=403, detail="Invalid API Key")


app = FastAPI(dependencies=[Depends(api_key_security)], lifespan=lifespan)

if OTEL_ENDPOINT:
    FastAPIInstrumentor.instrument_app(app)


@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    try:
        with (
            tracer.start_as_current_span("call_whisper_service")
            if tracer
            else trace.get_tracer("noop").start_as_current_span("noop")
        ):
            files = {"file": (file.filename, await file.read())}
            response = await clients["httpx"].post(
                "http://whisper:9000/transcribe", files=files
            )
            response.raise_for_status()
            return response.json()
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Whisper service unavailable: {e}")


class SpeakRequest(BaseModel):
    text: str


@app.post("/speak")
async def speak(data: SpeakRequest):
    piper_url = "http://piper:59125/api/tts"
    try:
        with (
            tracer.start_as_current_span("call_piper_service")
            if tracer
            else trace.get_tracer("noop").start_as_current_span("noop")
        ):
            async with clients["httpx"].stream(
                "POST", piper_url, json={"text": data.text}
            ) as r:
                r.raise_for_status()
                content = await r.aread()
                return Response(content=content, media_type="audio/wav")
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Piper service unavailable: {e}")
