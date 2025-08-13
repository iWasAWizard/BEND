# BEND/shared/fastapi_utils.py
"""
Shared utility functions for BEND's FastAPI services.
"""
import os
from fastapi import HTTPException, Depends, Header

API_KEY = os.getenv("BACKEND_API_KEY")


async def api_key_security(x_api_key: str = Header(None)):
    """A reusable dependency to protect endpoints with an API key."""
    if API_KEY:  # Security is enabled only if an API_KEY is set in the environment.
        if x_api_key is None:
            raise HTTPException(status_code=401, detail="API Key is missing")
        if x_api_key != API_KEY:
            raise HTTPException(status_code=403, detail="Invalid API Key")
