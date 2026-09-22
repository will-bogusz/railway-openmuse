# railway-openmuse

Container images for [OpenMuse](https://github.com/CopilotKit/OpenMuse) (MIT), built from a pinned
upstream commit with the application source unchanged. They back the Railway template
**[OpenMuse](https://railway.com/deploy/openmuse?referralCode=MYUCwz)** and run on any container host.

| image | built from | contents |
|---|---|---|
| `ghcr.io/will-bogusz/openmuse` | this repo's `Dockerfile` | API server (`pnpm build:server`), exported web client (`pnpm build:web`), Caddy |
| `ghcr.io/will-bogusz/openmuse-browser-worker` | upstream `apps/worker/Dockerfile`, unchanged | Playwright Chromium worker with persistent profiles |

Upstream publishes no images and has no Dockerfile for the API or the web client; these fill that
gap until it does.

## Deploy on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/openmuse?referralCode=MYUCwz)

The template deploys OpenMuse, a private browser worker and PostgreSQL. Supply your own
`CPK_INTELLIGENCE_API_KEY`, then log in with the generated `OPENMUSE_ACCESS_KEY` from Railway's
Variables tab. Configure `MODEL` and its provider key for chat and open-ended tasks.

[Setup and limitations](template/README.md) · [Exact template config](template/serializedConfig.json)
· [Deployment evidence](artifacts/2026-09-22/REPORT.md).

This is upstream alpha software. Browser automation is included; the Docker-based Linux
desktop/terminal is not. Conversations depend on CopilotKit Intelligence. The template is
single-workspace, protected by a generated key, not multi-tenant.

## `openmuse` runtime contract

One origin serves both halves: Caddy listens on `$PORT` (default 8080), serves the web client and
proxies `/api/*` to the API on `127.0.0.1:8787`. The web client's API URL is baked in at build time
upstream (`EXPO_PUBLIC_API_URL`), so the image builds it with a placeholder and the entrypoint
writes `PUBLIC_API_URL` into the bundle on every boot.

| variable | required | meaning |
|---|---|---|
| `PUBLIC_API_URL` | yes | this deployment's public URL, e.g. `https://openmuse.example.com` |
| `CPK_INTELLIGENCE_API_KEY` | yes (live mode) | CopilotKit Intelligence project key (`cpk-…`) |
| `OPENMUSE_ACCESS_KEY` | yes (live mode) | sign-in secret, 24+ characters |
| `TOKEN_ENCRYPTION_KEY` | yes (live mode) | 32 random bytes, base64 (`openssl rand -base64 32`) |
| `DATABASE_URL` | no | PostgreSQL; embedded PGlite under `DATA_DIR` when unset |
| `DATA_DIR` | no (`/data`) | documents, signing key and PGlite; mount a volume here |
| `BROWSER_WORKER_URL`, `WORKER_TOKEN` | no | the browser worker and its shared token (32+ characters) |
| `MODEL` + `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY` | no | e.g. `anthropic/<model-id>`; `OPENAI_BASE_URL` for an OpenAI-compatible Responses endpoint |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | no | Gmail and Calendar; redirect URI `${PUBLIC_API_URL}/api/google/callback` |

Image defaults: `WORKSPACE_MODE=live`, `AGENT_BACKEND=model`, `TASK_WORKER_ENABLED=true`,
`COMPUTER_ENABLED=false` (the optional Linux terminal needs a Docker engine). The entrypoint runs as
root only to take ownership of `DATA_DIR`, then runs Caddy and the API as `node`; it exits when
either exits. Healthcheck: `GET /api/health`.

The browser worker listens on 8790, reads `WORKER_TOKEN` and keeps profiles in `/data`. It runs as
`pwuser`; on a root-owned volume start it as root with
`sh -c 'chown pwuser:pwuser /data && exec setpriv --reuid=pwuser --regid=pwuser --init-groups node --experimental-strip-types src/index.ts'`.

## Build

**Actions → build → Run workflow** builds and pushes both images from the commit pinned in
`Dockerfile` (`ARG OPENMUSE_COMMIT`), tagged `<short sha>-YYYYMMDD`; the run summary prints both
`name:tag@sha256:…` references. To move to a newer upstream commit, change `OPENMUSE_COMMIT`, run
the workflow, then update the template's two image references.

## Licence

MIT (`LICENSE`). OpenMuse is MIT-licensed by its authors; the images include its `LICENSE`.
CopilotKit Intelligence is a separate hosted service with its own terms.
