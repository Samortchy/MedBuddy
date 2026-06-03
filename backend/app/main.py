from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
import asyncio
import logging
import time

from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.api.v1 import router
from app.core.limiter import limiter

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

# ── Rate limiting (Phase 6) ───────────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)


# ── Request logging middleware (Phase 6) ──────────────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start) * 1000
    logger.info(
        "%s %s -> %s (%.1f ms)",
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response


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
async def health():
    """Liveness + dependency checks for Supabase and the LLM provider."""
    from app.core.config import settings

    openrouter = (
        "configured"
        if settings.openrouter_api_key
        and settings.openrouter_api_key != "your-openrouter-api-key"
        else "missing"
    )

    supabase_status = "ok"
    try:
        from app.core.database import get_db
        get_db().table("profiles").select("id").limit(1).execute()
    except Exception as e:  # noqa: BLE001
        logger.warning("Health check: Supabase unreachable: %s", e)
        supabase_status = "down"

    return {
        "status": "ok",
        "service": "MedBuddy API",
        "supabase": supabase_status,
        "openrouter": openrouter,
    }