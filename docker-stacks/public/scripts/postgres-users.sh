#!/bin/sh
# Creates/updates one Postgres login per app from APP_USERS
# ("name:role:password;...", role = readwrite | readonly, "-" = none).
#   readwrite -> member of app_readwrite: read/write all tables in appdb.public,
#                may create tables (e.g. Flyway, Hibernate ddl-auto).
#   readonly  -> member of app_readonly:  SELECT only.
# Apps removed from APP_USERS are disabled (NOLOGIN); their tables are kept.
# Names and roles are validated by Terraform (var.app_users).
set -eu
export PGHOST=postgres PGUSER=postgres PGDATABASE=appdb PGPASSWORD="$POSTGRES_PASSWORD"

sql="
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readwrite') THEN CREATE ROLE app_readwrite NOLOGIN; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readonly')  THEN CREATE ROLE app_readonly  NOLOGIN; END IF;
END \$\$;
GRANT CONNECT ON DATABASE appdb TO app_readwrite, app_readonly;
GRANT USAGE, CREATE ON SCHEMA public TO app_readwrite;
GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA public TO app_readwrite;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO app_readwrite;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON TABLES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly;
"
names="''"

if [ "$APP_USERS" != "-" ]; then
  sql="$sql$(echo "$APP_USERS" | tr ';' '\n' | while IFS=: read -r name role password; do
    [ "$role" = readwrite ] && other=readonly || other=readwrite
    echo "
DO \$\$ BEGIN
  IF EXISTS (SELECT FROM pg_roles WHERE rolname = '$name') THEN ALTER ROLE $name LOGIN PASSWORD '$password';
  ELSE CREATE ROLE $name LOGIN PASSWORD '$password'; END IF;
END \$\$;
GRANT app_$role TO $name;
REVOKE app_$other FROM $name;"
    # Tables a readwrite app creates must be usable by the other apps too.
    [ "$role" = readwrite ] && echo "
ALTER DEFAULT PRIVILEGES FOR ROLE $name IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON TABLES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE $name IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE $name IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly;"
    echo "SELECT 'Synced $name ($role)';"
  done)"
  names="$(echo "$APP_USERS" | tr ';' '\n' | cut -d: -f1 | sed "s/.*/'&'/" | paste -sd, -)"
fi

sql="$sql
DO \$\$ DECLARE r record; BEGIN
  FOR r IN SELECT DISTINCT m.rolname FROM pg_roles m
           JOIN pg_auth_members am ON am.member = m.oid
           JOIN pg_roles g ON g.oid = am.roleid
           WHERE g.rolname IN ('app_readwrite', 'app_readonly') AND m.rolcanlogin
             AND m.rolname NOT IN ($names) LOOP
    EXECUTE format('ALTER ROLE %I NOLOGIN', r.rolname);
    RAISE NOTICE 'Disabled %', r.rolname;
  END LOOP;
END \$\$;
"

echo "$sql" | psql -v ON_ERROR_STOP=1 -qAt
