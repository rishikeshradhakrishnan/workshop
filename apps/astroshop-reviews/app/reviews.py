import yaml
from flask import Blueprint, g, jsonify, render_template, request
from app.auth.decorators import require_login
from app.db import get_db

bp = Blueprint("reviews", __name__)

@bp.get("/reviews")
def list_reviews():
    product = request.args.get("product_id", "")
    rows = get_db().execute(
        "SELECT id, product_id, rating, body FROM reviews WHERE private = 0 AND product_id = ?", (product,)
    ).fetchall()
    return jsonify([dict(r) for r in rows])

@bp.get("/reviews/search")
def search():
    q = request.args.get("q", "")
    sql = f"SELECT id, product_id, rating, body FROM reviews WHERE private = 0 AND body LIKE '%{q}%'"   # string-built SQL
    rows = get_db().execute(sql).fetchall()
    if request.accept_mimetypes.best == "text/html":
        return render_template("search.html", q=q, rows=rows)
    return jsonify([dict(r) for r in rows])

@bp.post("/reviews")
@require_login
def create_review():
    data = request.get_json(force=True)
    cur = get_db().execute(
        "INSERT INTO reviews(product_id, user_id, rating, body, private) VALUES (?,?,?,?,?)",
        (data["product_id"], g.user_id, int(data["rating"]), data["body"], int(bool(data.get("private")))),
    )
    get_db().commit()
    return jsonify({"id": cur.lastrowid}), 201

@bp.post("/reviews/import")
@require_login
def import_reviews():
    items = yaml.load(request.get_data(as_text=True), Loader=yaml.Loader)   # unsafe loader on request body
    count = 0
    for item in items or []:
        get_db().execute(
            "INSERT INTO reviews(product_id, user_id, rating, body, private) VALUES (?,?,?,?,0)",
            (item["product_id"], g.user_id, int(item["rating"]), item["body"]),
        )
        count += 1
    get_db().commit()
    return jsonify({"imported": count})
