# PR Description Details

## Live Deployment URL
- https://adewumi-test-production.up.railway.app/
- API Docs: https://adewumi-test-production.up.railway.app/docs

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
- The container entrypoint automatically runs migrations on start.
- The current `docker-compose.yml` only defines the `app` service. You must provide a PostgreSQL instance separately (or add one) and ensure `.env` points to it (e.g., `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`).

## Traefik Configuration Explanation
- There is no Traefik configuration in this repository. The app exposes HTTP via `php artisan serve` inside the container on `$PORT` (see `docker-entrypoint.sh`).
- In production, the platform (Railway) provides the reverse proxy/ingress and TLS termination. Locally, Docker exposes the container port directly (`8080:80` in `docker-compose.yml`).

## CI/CD Pipeline Instructions
- CI/CD is handled by Railway’s GitHub integration:
	1. Connect the GitHub repo to Railway.
	2. Railway builds the Docker image using `Dockerfile`.
	3. On deploy, the container runs `docker-entrypoint.sh`, which:
		 - Creates `.env` from Railway environment variables (supports `DATABASE_URL` or `PG*` vars).
		 - Ensures `APP_KEY` is set (uses the env var or generates one).
		 - Runs migrations (`php artisan migrate --force`).
		 - Starts the app on `$PORT`.

Required environment variables in Railway:
- `APP_URL` (set to the Railway public URL)
- `APP_KEY` (Laravel app key)
- `DATABASE_URL` **or** the standard `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`
- `PORT` (provided by Railway)

Optional variables:
- `APP_ENV=production`, `APP_DEBUG=false`
