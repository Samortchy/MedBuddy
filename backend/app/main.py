from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
import logging
from app.api.v1 import router

logger = logging.getLogger(__name__)

app = FastAPI(
    title="MedBuddy API",
    description="AI-Powered Medical Companion Backend",
    version="1.0.0",
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