import os
from flask import Blueprint, abort, current_app, send_file
from app.auth.decorators import require_login

bp = Blueprint("exports", __name__)

@bp.get("/exports/<path:name>")
@require_login
def download_export(name: str):
    path = os.path.join(current_app.config["EXPORT_DIR"], name)     # user-controlled path segment
    if not os.path.isfile(path):
        abort(404)
    return send_file(os.path.abspath(path))
