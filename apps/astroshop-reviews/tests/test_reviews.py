def test_list_public_reviews_for_product(client):
    resp = client.get("/reviews?product_id=telescope-01")
    assert resp.status_code == 200
    bodies = sorted(r["body"] for r in resp.get_json())
    assert bodies == ["Crisp optics", "Wobbly mount"]


def test_search_matches_body_text_and_hides_private(client):
    resp = client.get("/reviews/search?q=optics")
    assert resp.status_code == 200
    assert [r["body"] for r in resp.get_json()] == ["Crisp optics"]
    assert client.get("/reviews/search?q=gift").get_json() == []          # private review never appears in search


def test_create_review_requires_login_then_succeeds(client, login):
    payload = {"product_id": "lens-07", "rating": 4, "body": "Sharp to the edge"}
    assert client.post("/reviews", json=payload).status_code == 401
    resp = client.post("/reviews", json=payload, headers=login())
    assert resp.status_code == 201 and resp.get_json()["id"] > 0
    assert any(r["body"] == "Sharp to the edge" for r in client.get("/reviews?product_id=lens-07").get_json())
