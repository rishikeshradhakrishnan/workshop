from app.auth.tokens import issue_token, verify_token


def test_token_roundtrip_and_tamper_detection():
    token = issue_token(7, ttl=60)
    assert verify_token(token)["sub"] == 7
    header, payload, sig = token.split(".")
    assert verify_token(f"{header}.{payload}.{sig[:-2]}xx") is None      # bad signature
    assert verify_token("not-a-token") is None
    assert verify_token(issue_token(7, ttl=-10)) is None                    # expired
