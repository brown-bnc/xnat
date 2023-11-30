#!/usr/bin/env bash
set -eo pipefail
shopt -s nullglob 

warn() {
  >&2 echo "$@"
}

generate_xnat_conf() {
  if [ -z "${POSTGRES_HOST}" ] || [ -z "${POSTGRES_DB}" ] \
  || [ -z "${POSTGRES_USER}" ] || [ -z "${POSTGRES_PASSWORD}" ]; then
    echo "Error: Database configuration required" >&2
    exit 1
  fi

  cat > /data/xnat/home/config/xnat-conf.properties << EOF
datasource.driver=org.postgresql.Driver
datasource.url=jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT:-5432}/${POSTGRES_DB}
datasource.username=${POSTGRES_USER}
datasource.password=${POSTGRES_PASSWORD}

hibernate.dialect=org.hibernate.dialect.PostgreSQL9Dialect
hibernate.hbm2ddl.auto=update
hibernate.show_sql=false
hibernate.cache.use_second_level_cache=true
hibernate.cache.use_query_cache=true
EOF
}

generate_prefs_init() {
  if [ -z "${XNAT_SITE_URL}" ] || [ -z "${XNAT_ADMIN_EMAIL}" ]; then
    warn "\$XNAT_SITE_URL or \$XNAT_ADMIN_EMAIL not set. Not generating configs."
    return
  fi

  local email_verification='true'
  local auth_providers='["localdb"]'
  local auth_configs=( /data/xnat/home/config/auth/*.properties )
  local provider_id=''

  if [ -z "${XNAT_SMTP_HOSTNAME}" ] || [ -z "${XNAT_SMTP_USER}" ] \
  || [ -z "${XNAT_SMTP_PASSWORD}" ] || [ -z "${XNAT_SMTP_PORT}" ] \
  || [ -z "${XNAT_SMTP_AUTH}" ] || [ -z "${XNAT_SMTP_START_TLS}" ]; then
    email_verification="false"
  fi

  if [ "${#auth_configs[@]}" -gt 0 ]; then
    auth_providers='['
    for auth_config in "${auth_configs[@]}"; do
      provider_id="$(grep 'provider.id=' "${auth_config}" | cut -d= -f2)"
      auth_providers="${auth_providers}\"${provider_id}\","
    done
    auth_providers="${auth_providers}\"localdb\"]"
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
emailVerification=${email_verification}
enabledProviders=${auth_providers}
EOF

  if [ -z "${XNAT_SMTP_HOSTNAME}" ] || [ -z "${XNAT_SMTP_USER}" ] \
  || [ -z "${XNAT_SMTP_PASSWORD}" ] || [ -z "${XNAT_SMTP_PORT}" ] \
  || [ -z "${XNAT_SMTP_AUTH}" ] || [ -z "${XNAT_SMTP_START_TLS}" ]; then
    cat >> /data/xnat/home/config/prefs-init.ini << EOF

[notifications]
smtpEnabled=false
EOF
  else
    cat >> /data/xnat/home/config/prefs-init.ini << EOF

[notifications]
hostname=${XNAT_SMTP_HOSTNAME}
username=${XNAT_SMTP_USER}
password=${XNAT_SMTP_PASSWORD}
port=${XNAT_SMTP_PORT}
protocol=smtp
smtpAuth=${XNAT_SMTP_AUTH:-true}
smtpStartTls=${XNAT_SMTP_START_TLS:-true}
EOF
  fi
}

export_catalina_opts() {
  CATALINA_OPTS="${CATALINA_OPTS:-} -Dxnat.home=/data/xnat/home"

  if [ "${DEBUG:-}" ]; then
    CATALINA_OPTS="${CATALINA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
  fi

  export CATALINA_OPTS
}

main() {
  generate_xnat_conf
  generate_prefs_init
  export_catalina_opts

  export CATALINA_OPTS
  exec "${CATALINA_HOME}/bin/catalina.sh" "$@"
}

main "$@"
