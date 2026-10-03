# 2026-10-03: entrypoint supervision + Intelligence sign-up URL

Throwaway `kit-openmuse-sup-1003` (09d38c08-…, deleted, deletedAt 2026-10-05T21:07:59Z), template `openmuse` as published.

- Before (published image `fed01e9-20260922`): `kill -9` Caddy ended the ssh session; the next container's
  PID 1 had a new start time (ticks 260605918 → 260639497) — one ON_FAILURE restart spent. `before-kill-caddy.txt`.
- After: the same image plus this repo's new `entrypoint.sh` (`FROM ghcr.io/will-bogusz/openmuse:fed01e9-20260922@sha256:6706…`
  + `COPY entrypoint.sh`, built by Railway with `railway up`). Killed Caddy once and the API twice: PID 1 start
  ticks 260652148 unchanged throughout; Caddy back as pid 116, API as 202 then 279; `/api/health` through Caddy
  200 after each (502/ECONNREFUSED only in the 1–2 s gap). Logs: `openmuse: web exited with code 137; restarting it in 2s`,
  `openmuse: api exited with code 137; restarting it in 2s`, then `… in 4s`. `after-supervised-kills.txt`.
- A redeploy (SIGTERM path) replaced the container in ~25 s and public `/api/health` returned 200.
- Sign-up URL: `platform.copilotkit.ai` has no DNS (curl 000). CopilotKit's docs config sets
  `intelligenceSignupUrl: https://dashboard.operations.copilotkit.ai` behind the docs' "Get CopilotKit Intelligence free"
  button; the CLI `copilotkit@4.24.0` uses the same host as its ops frontend; the page title is
  "CopilotKit Intelligence — Operations" (HTTP 200). `project select --create <name>` exists in CLI 4.24.0.
