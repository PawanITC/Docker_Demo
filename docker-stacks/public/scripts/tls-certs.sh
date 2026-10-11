#!/bin/sh
# Hands the Let's Encrypt certificates that Caddy obtained for db.$PUBLIC_HOST
# and broker.$PUBLIC_HOST to Postgres and Kafka (shared `tls` volume):
#   /tls/db.crt, /tls/db.key   Postgres (key owned by uid 70 = postgres, 0600)
#   /tls/broker.p12            Kafka (PKCS12, password TLS_KEYSTORE_PASSWORD)
# Prints "Updated ..." when a certificate changed (used by renew-tls.sh).
set -eu
apk add --no-cache -q openssl

# Caddy keeps certs under /data/caddy/certificates/<issuer>/<host>/<host>.crt
find_cert() { ls /caddy/caddy/certificates/*/"$1"/"$1".crt 2>/dev/null | head -n 1; }

for host in "db.$PUBLIC_HOST" "broker.$PUBLIC_HOST"; do
  tries=0
  until [ -n "$(find_cert "$host")" ]; do
    tries=$((tries + 1))
    [ "$tries" -gt 60 ] && { echo "No certificate for $host after 5 min; see: docker compose logs caddy" >&2; exit 1; }
    echo "Waiting for Caddy to obtain a certificate for $host..."
    sleep 5
  done
done

crt=$(find_cert "db.$PUBLIC_HOST")
cmp -s "$crt" /tls/db.crt || echo "Updated db.$PUBLIC_HOST"
cp "$crt" /tls/db.crt
cp "${crt%.crt}.key" /tls/db.key
chown 70:70 /tls/db.crt /tls/db.key
chmod 600 /tls/db.key

crt=$(find_cert "broker.$PUBLIC_HOST")
cmp -s "$crt" /tls/broker.crt || echo "Updated broker.$PUBLIC_HOST"
cp "$crt" /tls/broker.crt
# Rebuilt every run so a new TLS_KEYSTORE_PASSWORD is picked up too.
openssl pkcs12 -export -in "$crt" -inkey "${crt%.crt}.key" -name broker \
  -out /tls/broker.p12 -passout env:TLS_KEYSTORE_PASSWORD
chmod 644 /tls/broker.p12   # password-protected; Kafka runs as a non-root user
echo "TLS files ready."
