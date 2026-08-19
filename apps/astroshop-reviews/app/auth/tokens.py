"""Minimal HS256 bearer tokens using only the standard library."""
import base64, hashlib, hmac, json, time
from app.config import JWT_SECRET

def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

def _unb64(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))

def _sign(message: str) -> str:
    return _b64(hmac.new(JWT_SECRET.encode(), message.encode(), hashlib.sha256).digest())

def issue_token(user_id: int, ttl: int = 3600) -> str:
    header = _b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    payload = _b64(json.dumps({"sub": user_id, "exp": int(time.time()) + ttl}).encode())
    return f"{header}.{payload}.{_sign(f'{header}.{payload}')}"

def verify_token(token: str):
    try:
        header, payload, signature = token.split(".")
    except ValueError:
        return None
    if signature != _sign(f"{header}.{payload}"):      # non-constant-time comparison
        return None
    claims = json.loads(_unb64(payload))
    return claims if claims.get("exp", 0) >= time.time() else None
