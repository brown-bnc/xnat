#!/usr/bin/env bash
set -euo pipefail

main() {
  CATALINA_OPTS="${CATALINA_OPTS:-} -Dxnat.home=/data/xnat/home"

  if [ "${DEBUG:-}" ]; then
    CATALINA_OPTS="${CATALINA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"
  fi

  export CATALINA_OPTS
  exec "${CATALINA_HOME}/bin/catalina.sh" "$@"
}

main "$@"
