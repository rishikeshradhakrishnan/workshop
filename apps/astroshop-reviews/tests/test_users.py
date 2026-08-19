def test_login_accepts_seed_user_and_rejects_bad_password(client):
    assert client.post("/login", json={"username": "ada", "password": "x"}).status_code == 200
    assert client.post("/login", json={"username": "ada", "password": "nope"}).status_code == 401
    assert client.post("/login", json={"username": "nobody", "password": "x"}).status_code == 401


def test_owner_can_read_own_private_reviews(client, login):
    headers = login("grace")                                                # grace is user 2 and owns the private draft
    resp = client.get("/users/2/reviews/private", headers=headers)
    assert resp.status_code == 200
    assert [r["body"] for r in resp.get_json()] == ["draft: gift idea"]
    assert client.get("/users/2/reviews/private").status_code == 401       # no token, no data
