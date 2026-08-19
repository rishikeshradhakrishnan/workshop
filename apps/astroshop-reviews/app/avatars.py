"""Avatar fetching helper. Unused on main; wired up by .workshop/introduce-ssrf.patch."""
import requests

def fetch_avatar(url: str, timeout: float = 5.0) -> tuple[bytes, str]:
    resp = requests.get(url, timeout=timeout, allow_redirects=True)   # no scheme/host allowlist
    resp.raise_for_status()
    return resp.content, resp.headers.get("Content-Type", "application/octet-stream")
