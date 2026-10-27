#!/usr/bin/env bash
# Verify that tomcat/server.xml, with our BNC BEGIN/END blocks removed, is identical to the
# stock server.xml of the latest Tomcat 9 release (the base image tracks tomcat:9-*).
# Fails with a diff if it changed, so our copy can be refreshed.
#
# Usage: scripts/check-server-xml.sh   (needs curl)
set -euo pipefail

ours="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tomcat/server.xml"

version="$(curl -fsS https://dlcdn.apache.org/tomcat/tomcat-9/ | grep -o 'v9\.0\.[0-9]*/' | tr -d v/ | sort -V | tail -n 1)"
stock_url="https://raw.githubusercontent.com/apache/tomcat/${version}/conf/server.xml"
stock="$(curl -fsS "${stock_url}")"

grep -q 'BNC BEGIN' "${ours}" || { echo "tomcat/server.xml has no BNC BEGIN/END blocks" >&2; exit 1; }

# Drop each BNC BEGIN ... BNC END block and the blank line that follows it, then compare
if ! diff -u --label "stock server.xml (Tomcat ${version})" --label "tomcat/server.xml (BNC blocks removed)" \
    <(printf '%s\n' "${stock}") \
    <(awk '/BNC BEGIN/ { skip = 1 }
           skip { if (/BNC END/) { skip = 0; blank = 1 } next }
           blank && /^[[:space:]]*$/ { blank = 0; next }
           { blank = 0; print }' "${ours}"); then
  echo >&2
  echo "tomcat/server.xml is out of date with Tomcat ${version}." >&2
  echo "Copy ${stock_url} to tomcat/server.xml and re-apply the BNC BEGIN/END blocks." >&2
  exit 1
fi

echo "tomcat/server.xml matches the stock file of Tomcat ${version} plus BNC additions"
