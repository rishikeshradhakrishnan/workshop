def test_export_download_and_missing_file(client, login):
    headers = login()
    ok = client.get("/exports/sample.csv", headers=headers)
    assert ok.status_code == 200 and ok.data.startswith(b"id,product_id")
    assert client.get("/exports/does-not-exist.csv", headers=headers).status_code == 404
    assert client.get("/exports/sample.csv").status_code == 401
