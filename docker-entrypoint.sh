#!/usr/bin/env bash
set -euo pipefail

generate_config() {
  if [ -z "${POSTGRES_HOST}" ] || [ -z "${POSTGRES_PORT}" ] \
  || [ -z "${POSTGRES_DB}" ] || [ -z "${POSTGRES_USER}" ] \
  || [ -z "${POSTGRES_PASSWORD}" ]; then
    echo "Error: Database configuration required" >&2
    exit 1
  fi

  cat > /data/xnat/home/config/xnat-conf.properties << EOF
datasource.driver=org.postgresql.Driver
datasource.url=jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
datasource.username=${POSTGRES_USER}
datasource.password=${POSTGRES_PASSWORD}

hibernate.dialect=org.hibernate.dialect.PostgreSQL9Dialect
hibernate.hbm2ddl.auto=update
hibernate.show_sql=false
hibernate.cache.use_second_level_cache=true
hibernate.cache.use_query_cache=true
EOF
}

generate_auth_config() {
  if [ -z "${LDAP_HOST}" ]; then
    return
  fi

  mkdir -p /data/xnat/home/config/auth
  cat > /data/xnat/home/config/auth/ldap-provider.properties << EOF
name=LDAP
provider.id=ldap
auth.method=ldap
visible=true
auto.enabled=true
auto.verified=true
address=${LDAP_HOST}
userdn=${LDAP_USER}
password=${LDAP_PASSWORD}
search.base=${LDAP_SEARCH_BASE}
search.filter=${LDAP_SEARCH_FILTER}
EOF
}

generate_site_config() {
  if [ -z "${XNAT_SITE_URL}" ] || [ -z "${XNAT_ADMIN_EMAIL}" ]; then
    return
  fi

  cat > /data/xnat/home/config/prefs-init.ini << EOF
[siteConfig]
siteUrl=${XNAT_SITE_URL}
adminEmail=${XNAT_ADMIN_EMAIL}
archivePath=/data/xnat/archive
buildPath=/data/xnat/build
cachePath=/data/xnat/cache
ftpPath=/data/xnat/ftp
pipelinePath=/data/xnat/pipeline
prearchivePath=/data/xnat/prearchive
initialized=true
EOF
}

generate_smtp_config() {
  if [ -z "${XNAT_SMTP_HOSTNAME}" ] || [ -z "${XNAT_SMTP_USER}" ] \
  || [ -z "${XNAT_SMTP_PASSWORD}" ] || [ -z "${XNAT_SMTP_PORT}" ] \
  || [ -z "${XNAT_SMTP_AUTH}" ] || [ -z "${XNAT_SMTP_START_TLS}" ]; then
    return
  fi

  cat >> /data/xnat/home/config/prefs-init.ini << EOF
[notifications]
hostname=${XNAT_SMTP_HOSTNAME}
username=${XNAT_SMTP_USER}
password=${XNAT_SMTP_PASSWORD}
port=${XNAT_SMTP_PORT}
protocol=smtp
smtpAuth=${XNAT_SMTP_AUTH}
smtpStartTls=${XNAT_SMTP_START_TLS}
EOF
}

set_catalina_opts() {
  CATALINA_OPTS="${CATALINA_OPTS:-} -Dxnat.home=/data/xnat/home"

  if [ "${DEBUG:-}" ]; then
    CATALINA_OPTS="${CATALINA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
  fi
}

main() {
  generate_config
  generate_auth_config
  generate_site_config
  generate_smtp_config
  set_catalina_opts

  export CATALINA_OPTS
  exec "${CATALINA_HOME}/bin/catalina.sh" "$@"
}

main "$@"
