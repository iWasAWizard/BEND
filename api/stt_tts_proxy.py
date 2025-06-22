from fastapi import FastAPI, UploadFile, File, Response
from pydantic import BaseModel
import requests

app = FastAPI()


@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    files = {"file": (file.filename, await file.read())}
    response = requests.post("http://whisper:9000/transcribe", files=files)
    return response.json()


class SpeakRequest(BaseModel):
    text: str


@app.post("/speak")
def speak(data: SpeakRequest):
    piper_url = "http://piper:59125/api/tts"
    with requests.post(piper_url, json={"text": data.text}, stream=True) as r:
        r.raise_for_status()
        return Response(content=r.content, media_type="audio/wav")
