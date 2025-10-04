# Xubudget HTTPS/HTTP3 Proxy Quickstart

- One origin: HTTPS proxy with HTTP/3 and Brotli in front of FastAPI + React build.
- No CORS/mixed content; mobile friendly.

## Scripts

- `RUN_PROXY_HTTPS.cmd`: build certs, build frontend, precompress, start API + proxy, open dashboard.
- `SMOKE_PROXY.cmd`: quick health checks via `https://localhost`.
- `STOP_PROXY.cmd`: stop API + proxy containers.
- `DEBUG_RULES.cmd`: debug AI rules endpoints locally (optional).

## Compose

- `docker-compose.yml`: base services (`api`, `ollama`, `web` for dev).
- `docker-compose.https.yml`: `web` (nginx) built with HTTP/3 + Brotli (`nginx/Dockerfile.quic-brotli`).

## Nginx security

- HSTS (dev/local): `max-age=31536000; includeSubDomains`.
- CSP (SPA): restrictive but compatible (camera/mic/screen, WS allowed).
- CSP (/api): hardened (`default-src 'none'; connect-src 'self'`).
- Permissions-Policy: minimal feature access.

## Notes

- For public domain, enable HSTS preload in `nginx/nginx.conf` and use a real TLS cert.
- QUIC requires UDP 443 open (script adds firewall rule on Windows).
