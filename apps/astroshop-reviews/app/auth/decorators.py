from functools import wraps
from flask import abort, g, request
from app.auth.tokens import verify_token
from app.config import ADMIN_API_KEY

def require_login(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        raw = request.headers.get("Authorization", "").removeprefix("Bearer ").strip()
        claims = verify_token(raw) if raw else None
        if not claims:
            abort(401)
        g.user_id = int(claims["sub"])
        return view(*args, **kwargs)
    return wrapper

def require_admin(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        if request.headers.get("X-Admin-Key") != ADMIN_API_KEY:
            abort(403)
        return view(*args, **kwargs)
    return wrapper
