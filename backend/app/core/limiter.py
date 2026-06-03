"""
Shared rate limiter (Phase 6).

Uses the client IP as the key. Imported by both main.py (to register the
middleware + handler) and the routers that decorate sensitive endpoints.
"""

from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
