from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Supabase
    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str
    supabase_jwt_secret: str

    # FastAPI
    app_env: str = "development"
    app_debug: bool = True
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    # Agora (Phase 4)
    agora_app_id: str = ""
    agora_app_certificate: str = ""

    # Firebase (Phase 2 — Bakr)
    firebase_service_account_json: str = ""

    # Twilio (Phase 2 — postponed)
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_from_number: str = ""

    # AI Models (Phase 3 — Ali)
    ollama_base_url: str = "http://localhost:11434"
    whisper_model_size: str = "large-v3"
    chatterbox_model_path: str = "./models/chatterbox"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()


# Single import shortcut used across the project
settings = get_settings()