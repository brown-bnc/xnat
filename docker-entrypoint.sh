#!/usr/bin/env bash
set -euo pipefail

generate_config() {
  sed -i'' \
    -e "s/@@POSTGRES_HOST@@/${POSTGRES_HOST}/" \
    -e "s/@@POSTGRES_PORT@@/${POSTGRES_PORT}/" \
    -e "s/@@POSTGRES_DB@@/${POSTGRES_DB}/" \
    -e "s/@@POSTGRES_USER@@/${POSTGRES_USER}/" \
    -e "s/@@POSTGRES_PASSWORD@@/${POSTGRES_PASSWORD}/" \
    /data/xnat/home/config/xnat-conf.properties
}

set_catalina_opts() {
  CATALINA_OPTS="${CATALINA_OPTS:-} -Dxnat.home=/data/xnat/home"

  if [ "${DEBUG:-}" ]; then
    CATALINA_OPTS="${CATALINA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
  fi
}

main() {
  generate_config
  set_catalina_opts

  export CATALINA_OPTS
  exec "${CATALINA_HOME}/bin/catalina.sh" "$@"
}

main "$@"
