# Security guidance for astroshop-reviews
- All SQL uses `?` placeholders through `get_db().execute(sql, params)`; any string-built SQL is a finding.
- Routes under `/users/<id>/…` must compare `<id>` with `g.user_id` unless decorated with `@require_admin`.
- Compare secrets, tokens and signatures with `hmac.compare_digest`, never `==` or `!=`.
- Outbound `requests` calls must validate scheme and host against `ALLOWED_AVATAR_HOSTS`; user-supplied URLs are untrusted.
- Never serve files by joining request data onto a directory; resolve and check containment first.
- `debug=True` is forbidden outside tests.
