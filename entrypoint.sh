#!/bin/bash
# Boot: own the data volume, point the web client at this deployment's URL,
# then run the API (loopback) and Caddy (public port) as the unprivileged
# `node` user. Exits when either process exits so the platform restarts it.
set -euo pipefail

fail() { echo "openmuse: $*" >&2; sleep 3; exit 1; }

PUBLIC_PORT="${PORT:-8080}"
API_PORT=8787
PUBLIC_URL="${PUBLIC_API_URL:-}"
PUBLIC_URL="${PUBLIC_URL%/}"
[ -n "$PUBLIC_URL" ] || fail "PUBLIC_API_URL is empty. Set it to this service's public https URL."
case "$PUBLIC_URL" in http://* | https://*) ;; *) fail "PUBLIC_API_URL must start with http:// or https://, got '$PUBLIC_URL'" ;; esac
case "$PUBLIC_PORT" in '' | *[!0-9]*) fail "PORT must be a number, got '$PUBLIC_PORT'" ;; esac
[ "$PUBLIC_PORT" != "$API_PORT" ] || fail "PORT must not be $API_PORT; the API listens there on loopback."

# The browser and the API share one origin, so it is always an allowed origin.
export ALLOWED_ORIGINS="${ALLOWED_ORIGINS:-$PUBLIC_URL}"

if [ "$(id -u)" = 0 ]; then
	mkdir -p "$DATA_DIR"
	# Platform volumes mount root-owned; hand the top directory to node once.
	[ "$(stat -c %U "$DATA_DIR")" = node ] || chown node:node "$DATA_DIR"
	chmod 0700 "$DATA_DIR"
fi

rm -rf /srv/web
mkdir -p /srv
cp -a /app/web /srv/web
grep -rlZ __OPENMUSE_PUBLIC_URL__ /srv/web | xargs -0 -r sed -i "s#__OPENMUSE_PUBLIC_URL__#${PUBLIC_URL}#g"

export OPENMUSE_PUBLIC_PORT="$PUBLIC_PORT" OPENMUSE_API_PORT="$API_PORT"
export HOME=/home/node XDG_CONFIG_HOME=/tmp XDG_DATA_HOME=/tmp

run() {
	cd /app
	PORT="$API_PORT" HOST=127.0.0.1 node dist/apps/server/src/index.js &
	local api=$!
	caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
	local web=$!
	trap 'kill -TERM "$api" "$web" 2>/dev/null' TERM INT
	echo "openmuse: web client and API on :$PUBLIC_PORT, public URL $PUBLIC_URL"
	set +e
	wait -n "$api" "$web"
	local code=$?
	kill -TERM "$api" "$web" 2>/dev/null
	wait
	exit "$code"
}
export -f run fail
export PUBLIC_URL PUBLIC_PORT API_PORT

if [ "$(id -u)" = 0 ]; then
	exec setpriv --reuid=node --regid=node --init-groups --inh-caps=-all bash -c run
fi
run
