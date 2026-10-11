# Grafana OSS with a PostgreSQL data source provisioned automatically.
FROM grafana/grafana-oss:11.2.0

ENV GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_ADMIN_PASSWORD=admin \
    GF_USERS_ALLOW_SIGN_UP=false

# Anything under /etc/grafana/provisioning is loaded at start-up.
COPY provisioning/ /etc/grafana/provisioning/

# Dashboards, users, plugins and the internal SQLite DB.
VOLUME /var/lib/grafana

EXPOSE 3000
