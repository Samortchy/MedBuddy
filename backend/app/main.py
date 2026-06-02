from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
import asyncio
import logging
from app.api.v1 import router

logger = logging.getLogger(__name__)


def _preload_models():
    """Load STT and TTS models into memory at startup (runs in a thread)."""
    try:
        from app.services import stt_service
        stt_service.load_model()
        logger.info("STT model preloaded.")
    except Exception as e:
        logger.warning("STT preload failed (non-fatal): %s", e)

    try:
        from app.services import tts_service
        tts_service._load_model()
        logger.info("TTS model preloaded.")
    except Exception as e:
        logger.warning("TTS preload failed (non-fatal): %s", e)


@asynccontextmanager
async def lifespan(app: FastAPI):
    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, _preload_models)
    logger.info("Model preloading started in background.")
    yield


app = FastAPI(
    title="MedBuddy API",
    description="AI-Powered Medical Companion Backend",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(router.router, prefix="/api/v1")


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    body = None
    try:
        body = await request.json()
    except Exception:
        pass
    logger.error(
        f"422 Validation Error | {request.method} {request.url.path}\n"
        f"  body={body}\n"
        f"  errors={exc.errors()}"
    )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()},
    )


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "service": "MedBuddy API"}