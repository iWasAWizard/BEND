from fastapi import FastAPI, UploadFile, File, Response, HTTPException, Depends, Header
from pydantic import BaseModel
from contextlib import asynccontextmanager
import httpx
import os
import logging
import sys
from pythonjsonlogger import jsonlogger

# --- Logging Setup ---
logHandler = logging.StreamHandler(sys.stdout)
formatter = jsonlogger.JsonFormatter(
    fmt="%(asctime)s %(name)s %(levelname)s %(message)s"
)
logHandler.setFormatter(formatter)
logging.basicConfig(handlers=[logHandler], level=logging.INFO)
logging.getLogger("uvicorn.access").disabled = True
# --- End Logging Setup ---

# OpenTelemetry Imports
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider, NoOpTracer
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# --- Tracing Setup ---
API_KEY = os.getenv("BEND_API_KEY")
OTEL_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
clients = {}
tracer: trace.Tracer

if OTEL_ENDPOINT:
    provider = TracerProvider()
    processor = BatchSpanProcessor(
        OTLPSpanExporter(endpoint=OTEL_ENDPOINT, insecure=True)
    )
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)
    tracer = trace.get_tracer(__name__)
else:
    tracer = NoOpTracer()
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
        with tracer.start_as_current_span("call_whisper_service"):
            # The new whisper-server does not need the model name in the payload.
            # It only expects the multipart file upload.
            files = {"file": (file.filename, await file.read(), file.content_type)}
            response = await clients["httpx"].post(
                "http://whisper:9000/inference", files=files
            )
            response.raise_for_status()
            return response.json()
    except httpx.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Whisper service unavailable: {e}")


class SpeakRequest(BaseModel):
    text: str


@app.post("/speak")
async def speak(data: SpeakRequest):
    piper_url = "http://piper:59125/api/tts"
    try:
        with tracer.start_as_current_span("call_piper_service"):
            async with clients["httpx"].stream(
                "POST", piper_url, json={"text": data.text}
            ) as r:
                r.raise_for_status()
                content = await r.aread()
                return Response(content=content, media_type="audio/wav")
    except httpx.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Piper service unavailable: {e}")
