#!/usr/bin/env bash
# Caddy renews the Let's Encrypt certs on its own (~every 60 days); this copies
# a renewed cert to Postgres (reload, no downtime) and Kafka (restart, ~30 s).
# Run it weekly from cron on the EC2 instance:
#   (crontab -l 2>/dev/null; echo "0 4 * * 1 $PWD/renew-tls.sh >> $PWD/renew-tls.log 2>&1") | crontab -
set -euo pipefail
cd "$(dirname "$0")"

out=$(docker compose run --rm --no-deps tls-certs)
echo "$(date -Is) $out"
if grep -q "^Updated db\." <<<"$out"; then
  docker compose kill -s HUP postgres
fi
if grep -q "^Updated broker\." <<<"$out"; then
  docker compose restart kafka
fi
