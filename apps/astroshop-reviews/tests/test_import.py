IMPORT_YAML = """
- product_id: binoculars-02
  rating: 5
  body: Great for star parties
- product_id: binoculars-02
  rating: 3
  body: Heavier than expected
"""


def test_import_reviews_from_yaml(client, login):
    resp = client.post("/reviews/import", data=IMPORT_YAML, headers=login(), content_type="text/yaml")
    assert resp.status_code == 200 and resp.get_json() == {"imported": 2}
    assert len(client.get("/reviews?product_id=binoculars-02").get_json()) == 2
