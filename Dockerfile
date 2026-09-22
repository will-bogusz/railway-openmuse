# syntax=docker/dockerfile:1
#
# OpenMuse (github.com/CopilotKit/OpenMuse) as one container: the API server and
# the exported web client on a single origin. Caddy serves the client and proxies
# /api/* to the API on loopback, so the browser, the OAuth callback and signed
# file links all share one public URL. Upstream source is built unchanged from a
# pinned commit; see README.md for the runtime contract and how to bump it.

ARG NODE_IMAGE=node:24.21.0-bookworm-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6
ARG CADDY_IMAGE=caddy:2.11.4-alpine@sha256:de23def33b17fb5d1290b0f6c2add1d70780e52341896c00a4c8a2a2fe9d355e

FROM ${NODE_IMAGE} AS source
ARG OPENMUSE_REPO=https://github.com/CopilotKit/OpenMuse.git
ARG OPENMUSE_COMMIT=fed01e9d6411ab773d9adf1aa490a07dc8c64d0b
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && git clone --filter=blob:none --no-checkout "$OPENMUSE_REPO" /src \
 && git -C /src checkout --quiet "$OPENMUSE_COMMIT" \
 && rm -rf /src/.git /var/lib/apt/lists/*

FROM ${NODE_IMAGE} AS build
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 CI=true
RUN corepack enable
WORKDIR /src
COPY --from=source /src /src
RUN pnpm install --frozen-lockfile
RUN pnpm build:server
# EXPO_PUBLIC_* values are inlined into the bundle. The placeholder is replaced
# with the deployment's public URL when the container starts (entrypoint.sh).
RUN EXPO_PUBLIC_API_URL=__OPENMUSE_PUBLIC_URL__ pnpm build:web \
 && grep -rqs __OPENMUSE_PUBLIC_URL__ apps/mobile/dist/web

# Production dependencies of the server (the root workspace package) only.
FROM ${NODE_IMAGE} AS deps
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 CI=true
RUN corepack enable
WORKDIR /src
COPY --from=source /src/package.json /src/pnpm-lock.yaml /src/pnpm-workspace.yaml /src/.npmrc ./
COPY --from=source /src/apps/mobile/package.json apps/mobile/package.json
COPY --from=source /src/apps/worker/package.json apps/worker/package.json
RUN pnpm install --frozen-lockfile --prod --filter openmuse

FROM ${CADDY_IMAGE} AS caddy

FROM ${NODE_IMAGE}
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
WORKDIR /app
COPY --from=deps /src/node_modules ./node_modules
COPY --from=build /src/package.json ./package.json
COPY --from=build /src/dist ./dist
COPY --from=build /src/apps/mobile/dist/web ./web
COPY --from=source /src/LICENSE ./LICENSE
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENV NODE_ENV=production \
    DATA_DIR=/data \
    WORKSPACE_MODE=live \
    AGENT_BACKEND=model \
    TASK_WORKER_ENABLED=true \
    COMPUTER_ENABLED=false \
    PORT=8080
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
