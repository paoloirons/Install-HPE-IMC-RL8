#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_NAME="04_post_install"
log(){ echo "[$SCRIPT_NAME] $*"; }
fail(){ echo "[$SCRIPT_NAME][ERROR] $*" >&2; exit 1; }
IMC_HOME="${IMC_HOME:-/opt/iMC}"; BIN_DIR="${IMC_HOME}/bin"; HOSTNAME_FQDN="${HOSTNAME_FQDN:-imc-hpe.aopro.it}"; SERVER_IP="${SERVER_IP:-10.10.0.5}"; HTTP_PORT="${HTTP_PORT:-8080}"; HTTPS_PORT="${HTTPS_PORT:-8443}"
[[ -d "$BIN_DIR" ]] || fail "Directory IMC non trovata: ${BIN_DIR}"
ACTION="${1:-status}"
case "$ACTION" in
  start) cd "$BIN_DIR"; ./start.sh ;;
  stop) cd "$BIN_DIR"; ./stop.sh ;;
  restart) cd "$BIN_DIR"; ./stop.sh || true; sleep 5; ./start.sh ;;
  status) log "Processi IMC"; pgrep -af -i imc || true; echo; log "Porte principali"; ss -lntp | grep -E ":(${HTTP_PORT}|${HTTPS_PORT})[[:space:]]" || true; echo; log "Hostname"; hostnamectl status | sed -n '1,12p'; echo; log "Risoluzione locale"; getent hosts "$HOSTNAME_FQDN" || true; echo; log "MariaDB"; systemctl --no-pager --full status mariadb | sed -n '1,12p' || true ;;
  *) fail "Uso: $0 {start|stop|restart|status}" ;;
esac
cat <<EOF

URL IMC:
  http://${SERVER_IP}:${HTTP_PORT}/imc
  https://${SERVER_IP}:${HTTPS_PORT}/imc
  https://${HOSTNAME_FQDN}:${HTTPS_PORT}/imc
EOF
