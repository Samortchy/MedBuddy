from fastapi import FastAPI
from app.api.v1 import router

app = FastAPI(
    title="MedBuddy API",
    description="AI-Powered Medical Companion Backend",
    version="1.0.0",
)

app.include_router(router.router, prefix="/api/v1")


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "service": "MedBuddy API"}