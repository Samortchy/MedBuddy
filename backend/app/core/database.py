from supabase import create_client, Client
from app.core.config import settings

# Single Supabase client instance — created once on startup
# Uses service role key so it bypasses RLS
# All auth/scoping is handled manually in route handlers via JWT
_supabase_client: Client = create_client(
    settings.supabase_url,
    settings.supabase_service_role_key,
)


def get_db() -> Client:
    """
    FastAPI dependency — returns the shared Supabase client.

    Usage in routes:
        from fastapi import Depends
        from app.core.database import get_db
        from supabase import Client

        @router.get("/example")
        async def example(db: Client = Depends(get_db)):
            result = db.table("appointments").select("*").execute()
            return result.data
    """
    return _supabase_client