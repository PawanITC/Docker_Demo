#!/bin/bash
# Creates/updates one Kafka SCRAM-SHA-512 user per app from APP_USERS
# ("name:role:password;...", role = readwrite | readonly, "-" = none).
#   readwrite -> produce + consume on all topics, create topics, transactions.
#   readonly  -> consume (read topics, use consumer groups) only.
# Apps removed from APP_USERS lose their password and ACLs.
# Runs over the internal PLAINTEXT listener (User:ANONYMOUS = super user).
set -euo pipefail
B=kafka:29092
cfg() { kafka-configs --bootstrap-server "$B" "$@"; }
acl() { kafka-acls --bootstrap-server "$B" "$@" >/dev/null; }
read_acls=(--consumer --topic '*' --group '*')
write_acls=(--producer --topic '*' --transactional-id '*' --idempotent)

wanted=" "
if [ "$APP_USERS" != "-" ]; then
  while IFS=: read -r name role password; do
    cfg --alter --entity-type users --entity-name "$name" \
      --add-config "SCRAM-SHA-512=[iterations=8192,password=$password]" >/dev/null
    acl --add --allow-principal "User:$name" "${read_acls[@]}"
    if [ "$role" = readwrite ]; then
      acl --add --allow-principal "User:$name" "${write_acls[@]}"
    else
      acl --remove --force --allow-principal "User:$name" "${write_acls[@]}"
    fi
    echo "Synced $name ($role)"
    wanted="$wanted$name "
  done < <(echo "$APP_USERS" | tr ';' '\n')
fi

# Only app users have SCRAM credentials, so any other one was removed from APP_USERS.
for name in $(cfg --describe --entity-type users | sed -n "s/^SCRAM credential configs for user-principal '\([^']*\)'.*/\1/p"); do
  [[ "$wanted" == *" $name "* ]] && continue
  cfg --alter --entity-type users --entity-name "$name" --delete-config SCRAM-SHA-512 >/dev/null
  acl --remove --force --allow-principal "User:$name" "${read_acls[@]}"
  acl --remove --force --allow-principal "User:$name" "${write_acls[@]}"
  echo "Removed $name"
done
