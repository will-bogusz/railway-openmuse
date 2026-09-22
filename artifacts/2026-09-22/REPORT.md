# OpenMuse Railway template — 2026-09-22

## Published result

- Template: **[OpenMuse](https://railway.com/deploy/openmuse)**, code `openmuse`, immutable id `bfe67c31-595a-4a32-9cce-88ab91344d80`.
- Publication and exact API read-back: `published.json`. Live config equals `template/serializedConfig.json`; the 8,049-byte overview equals `template/README.md`.
- Three services and 40 variables. The only required blank input is `CPK_INTELLIGENCE_API_KEY`; nine OpenMuse configuration fields and the Postgres certificate-duration field are optional.
- Initial owner metrics: health 100, search position 1 for `openmuse` and `open muse`. One deployment/active project at the snapshot was our QA project, not customer demand. Marketplace counters are eventually consistent.
- No public demo deployment is maintained. The listing and images are the deliverables.

## Source and provenance

The source is CopilotKit/OpenMuse at `fed01e9d6411ab773d9adf1aa490a07dc8c64d0b`, MIT. It is built unchanged. The application image adds packaging only: server build, Expo web export and a Caddy same-origin proxy. The browser image uses upstream's Dockerfile unchanged.

[GitHub Actions run 35790305065](https://github.com/will-bogusz/railway-openmuse/actions/runs/35790305065) successfully built and published Linux amd64 images:

- App: `ghcr.io/will-bogusz/openmuse:fed01e9-20260922@sha256:67063ca1a871c563332525699e9da80618e7acbe00de35a0bf755bdd0d3a6a73`
- Browser: `ghcr.io/will-bogusz/openmuse-browser-worker:fed01e9-20260922@sha256:f6c625b5bffc5c65c912ed4b128a1e8ac2323107b8ab153d4cde05cad5549cf6`
- Postgres: Railway's PostgreSQL 18 image, using its published variable contract and a persistent database volume.

Railway pulled both images without registry credentials. `/proc/1/status` in the deployed application confirmed that the process supervisor ran as uid 1000.

The original intake found no OpenMuse marketplace template. Upstream's company has explicitly declined third-party hosting-provider README buttons in [OpenBot PR #346](https://github.com/CopilotKit/OpenBot/pull/346). This is a community marketplace distribution, not an upstream endorsement. No upstream PR, issue, comment or social post was made during this run.

## Fresh-deployment QA

All cloud tests used a fresh deployment of the final template, not a hand-wired existing instance. The initial deployment supplied exactly one value: a dedicated CopilotKit Intelligence project key. Provider settings were added only to that temporary project after the no-model startup was proven.

| Check | Direct observation |
|---|---|
| Required-input negative control | Non-TTY deployment without a key failed with Railway's required-input prompt; no other blank-required variable. |
| Schema | Target passed the kit's Railway JSON Schema. |
| Readiness | All three services reached `SUCCESS`; app and Browser deployment images matched their pinned digests. |
| Generated credentials | Access key 32 characters, worker token 48 characters, encryption key canonical base64 decoding to exactly 32 bytes. |
| No-model startup | `/api/health` returned 200, live mode, `agentConfigured=false`, `browserConfigured=true`. |
| Access gate | `/api/workspace` without a token returned 401; wrong login key 401; correct key 200. |
| Real model chat | OpenRouter Responses with `openai/openai/gpt-4o-mini` returned `42` for 6×7 in the web UI. |
| Real browser read | Chat called the private worker, rendered a browser preview, and returned `Example Domain` from example.com. |
| Browser takeover | Live iframe controls loaded; entering example.org in the address bar navigated the same browser session successfully. |
| Background work | Task initially paused in Waiting input. A continuation completed a real `read_web`, `finish_task`, source evidence and a saved report. No synthetic model responses. |
| Document upload | Upstream's synthetic two-page PDF uploaded successfully; authenticated content returned 7,647 bytes. |
| Phone layout | 390×844 viewport, document scroll width 390. `phone-chat.png` shows real chat and the browser result. |
| App and browser redeploy | Both new deployments reached `SUCCESS`; original session token stayed valid, file hash unchanged, goal and successful task/report persisted. |
| Browser profile reopen | The same session/profile id reopened after Browser redeploy; it read example.org and returned `Example Domain`. Signed-in website cookies were not tested. |
| Database restart | An authenticated workspace probe saw 54/55 HTTP 200 responses, one HTTP 502, then automatic recovery to 200. |
| Logs | Initial app startup scan found one start and no known crash signatures. |
| Docker computer | API explicitly reported disabled/unconfigured, consistent with template scope and documentation. |

File SHA-256 across redeploy: `0e862a72bbc321cb5d76c4ac9f8ac1aa9d3c64efb32b9dbf61b56010840434a8`.

Structured evidence: `qa.json`, `database-restart-probe.json`, the pre-QA configuration and the published snapshot.

### Availability is not zero-downtime

The app redeploy probe returned **65/66 HTTP 200**, with one request timing out after ten seconds. Its strict continuity rung is **FAIL**, not silently relabelled PASS. The persistence/recovery checks passed. The overview explains Railway's volume-attached redeploy interruption and that `/api/health` is a process/configuration check, not a database/model/browser end-to-end check.

### Upstream alpha limitation

With the inexpensive test model, initial delegated tasks repeatedly ended in Waiting input without invoking their completion tool. Explicit continuation succeeded. Source inspection also found that `engine/model.ts` collects `TEXT_MESSAGE_CONTENT` while this runtime can emit `TEXT_MESSAGE_CHUNK`; that can lose plain-text task updates, but it does not itself explain or prevent tool execution. No application patch, automatic retry or fake completion was added. The listing describes the limitation.

### Scope not exercised

Google OAuth and connected-account actions, a remote AG-UI harness, alternative model providers, a Docker Linux desktop, and real signed-in browser-session cookies were not tested. Their presence in upstream documentation is not represented as QA proof. No real email, calendar write, purchase or third-party account action was performed.

## Measurement and maintenance

An early five-minute window including QA and restarts averaged 433.717 MB and 0.023338 vCPU across the three services, with summed per-service peaks of 630.937 MB. Its RAM/CPU extrapolation was $4.71/month at the kit's dated Railway rates. This mixed-activity sample is not a quiet-idle estimate or a promised bill. Provider and CopilotKit charges are separate.

### Quiet ten-minute sample

After the functional and recovery tests, all QA browser tabs were closed and the stack was left without interactive requests for ten minutes. The sample ending 22:49:44 UTC measured:

| Service | Average RAM | Average vCPU |
|---|---:|---:|
| OpenMuse | 125.489 MB | 0.001439 |
| Browser | 165.229 MB | 0.000214 |
| Postgres | 61.537 MB | 0.001095 |
| **Total** | **352.255 MB** | **0.002748** |

That is **$3.50/month for idle RAM and CPU**, before volume storage, egress, model/provider charges, CopilotKit charges and Railway plan minimums. Summed per-service peaks were 434.949 MB and 0.010843 vCPU; these are not a simultaneous stack-peak measurement. Rates used were $10.01/GB-month and $20.01/vCPU-month, verified by the kit on 2026-09-01. `footprint.txt` contains the complete measurement output. This ten-minute observation is not a load/capacity test or an uptime promise.

The final pre-teardown Railway usage snapshot was **$0.0020**, well below the $2 Railway run budget. Usage can lag roughly seven minutes, so this is a captured lower-bound snapshot rather than an audited final invoice. Provider inference spend was not independently measured. The usage script's traffic factor is a kit-wide heuristic, not observed OpenMuse traffic.

### Daily watch

A daily owner-metrics watch uses the kit's existing `snapshot-metrics.sh`, scheduled at 09:15 local and on load. Its first on-load run exited 0 and recorded health, deployments, earnings and both search positions. Runtime rows live under this repository's ignored `artifacts/watch/` directory. It does not publish changes or send messages. Use the template id above with the kit script to reproduce the snapshot.

The community images remain pinned. Rebuild/test before upgrades; users' existing deployments do not automatically inherit marketplace edits. Upstream image publication should replace community image maintenance when a compatible official image is available.

## Teardown

Both temporary OpenMuse Railway projects were deleted and owner-API `deletedAt` values were verified:

- Template build: `1c4630c9-333f-4ff6-b979-7921e7da2b66`, purge marker `2026-09-24T22:43:04.194Z`.
- Fresh QA: `c8b2561b-b226-4781-9e73-460c892da9b1`, purge marker `2026-09-24T22:50:34.604Z`.

These are Railway's scheduled purge markers; the project deletion itself occurred on September 22. No OpenMuse QA service was intentionally retained. Local lab containers, their inspected data volumes and their private Docker network were removed. Images, source and the published template remain. `usage-and-teardown.txt` contains the captured results.

Task-created browser tabs were closed. The user's original Railway tab was released and left open. Retained text artifacts were scanned for known test credentials and common GitHub/OpenAI/OpenRouter key patterns before publication; none were found.
