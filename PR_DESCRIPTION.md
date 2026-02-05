# PR Description Details

## Live Deployment URL
- https://adewumi-test-production.up.railway.app/
- API Docs: https://adewumi-test-production.up.railway.app/docs
- Postman Base URL: https://adewumi-test-production.up.railway.app/

## Architectural Decisions (Summary)
- Built with Laravel 11 as an API-first service focused on a single domain: secure, burn-on-read notes.
- Service-Repository pattern separates concerns:
	- `SecretController` handles validation and HTTP responses.
	- `SecretService` encapsulates business logic (create, retrieve, delete).
	- `SecretRepository` isolates persistence and DB operations.
- Model-level encryption via Laravel `Crypt` ensures note contents are stored encrypted at rest.
- UUID-based public identifiers avoid sequential IDs and reduce enumeration risk.
- Burn-on-read and optional TTL enforce data minimization and automatic deletion.
- PostgreSQL is the primary datastore (see `DB_CONNECTION=pgsql`).

## API Payloads

### POST /api/v1/secrets
Creates a new secure note.

Headers:
- `Content-Type: application/json`
- `Accept: application/json`

Request:
{
	"text": "My secret password",
	"ttl": 60
}

Response (201):
{
	"id": "550e8400-e29b-41d4-a716-446655440000",
	"url": "http://localhost:8000/api/v1/secrets/550e8400-e29b-41d4-a716-446655440000"
}

### GET /api/v1/secrets/{id}
Retrieves and permanently deletes a secret (burn-on-read).

Headers:
- `Accept: application/json`

Response (200):
{
	"text": "My secret password"
}

## Local Run Instructions (One Command Setup)
- Copy environment file once, then run a single command to start the app:
	- `cp .env.example .env`
	- `docker compose up -d --build`

Notes:
- This setup now includes Traefik and PostgreSQL in Docker Compose.
- For local routing, map `secure-drop.localhost` to `127.0.0.1` in your hosts file.
- The container entrypoint automatically runs migrations on start.

## Traefik Configuration Explanation
- Traefik is defined in `docker-compose.yml` and acts as the reverse proxy.
- Routing uses Docker labels on the `app` service:
	- Router rule: `Host(secure-drop.localhost)` (or `TRAEFIK_HOST` env)
	- EntryPoint: `web` (port 80)
	- Service target port: `$PORT` (default `8000`)
- Production overrides (`docker-compose.prod.yml`) enable TLS with Let’s Encrypt via the `websecure` entrypoint and ACME config.

## CI/CD Pipeline Instructions
- GitHub Actions workflow in `.github/workflows/ci.yml`:
	1. **Lint & Test**: Runs `vendor/bin/pint --test` and `php artisan test` against a Postgres service.
	2. **Security Scan**: Builds the Docker image and scans it with Trivy (fails on HIGH/CRITICAL).
	3. **Build & Push**: Builds and pushes the Docker image to GHCR.
	4. **(Optional) Deploy**: SSH step to pull the latest image and run compose on a VPS.

Required GitHub Secrets for deploy (optional):
- `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`
