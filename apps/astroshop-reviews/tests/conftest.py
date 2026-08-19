import os
import shutil
import tempfile

import pytest

from app import create_app
from app.db import init_db


@pytest.fixture()
def app():
    workdir = tempfile.mkdtemp(prefix="astroshop-reviews-")
    export_dir = os.path.join(workdir, "exports")
    os.makedirs(export_dir)
    with open(os.path.join(export_dir, "sample.csv"), "w") as fh:
        fh.write("id,product_id,rating\n1,telescope-01,5\n")
    flask_app = create_app({"TESTING": True, "DATABASE": os.path.join(workdir, "test.db"), "EXPORT_DIR": export_dir})
    with flask_app.app_context():
        init_db(seed=True)
    yield flask_app
    shutil.rmtree(workdir, ignore_errors=True)


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture()
def login(client):
    """Return a callable that logs a seeded user in and returns an Authorization header dict."""
    def _login(username="ada", password="x"):
        resp = client.post("/login", json={"username": username, "password": password})
        assert resp.status_code == 200, resp.data
        return {"Authorization": f"Bearer {resp.get_json()['token']}"}
    return _login
