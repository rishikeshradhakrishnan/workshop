from flask import Blueprint, abort, jsonify, request
from app.auth.decorators import require_login
from app.auth.tokens import issue_token
from app.db import get_db

bp = Blueprint("users", __name__)

@bp.post("/login")
def login():
    data = request.get_json(force=True)
    row = get_db().execute(
        "SELECT id, password_hash FROM users WHERE username = ?", (data.get("username", ""),)
    ).fetchone()
    if row is None or row["password_hash"] != data.get("password"):   # (password hashing is out of scope for the lab)
        abort(401)
    return jsonify({"token": issue_token(row["id"])})

@bp.get("/users/<int:user_id>/reviews/private")
@require_login
def private_reviews(user_id: int):
    # Missing: user_id must equal g.user_id
    rows = get_db().execute(
        "SELECT id, product_id, rating, body FROM reviews WHERE private = 1 AND user_id = ?", (user_id,)
    ).fetchall()
    return jsonify([dict(r) for r in rows])
