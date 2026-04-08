#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="03_install_imc"

log() {
  echo "[$SCRIPT_NAME] $*"
}

fail() {
  echo "[$SCRIPT_NAME][ERROR] $*" >&2
  exit 1
}

require_root() {
  [[ $EUID -eq 0 ]] || fail "Esegui lo script come root."
}

require_root

HOSTNAME_FQDN="${HOSTNAME_FQDN:-imc-hpe.aopro.it}"
SERVER_IP="${SERVER_IP:-10.10.0.5}"

DB_NAME="${DB_NAME:-imc_db}"
DB_USER="${DB_USER:-imc}"
DB_PASS="${DB_PASS:-ChangeMe_Str0ng!}"
DB_HOST="${DB_HOST:-localhost}"

HTTP_PORT="${HTTP_PORT:-8080}"
HTTPS_PORT="${HTTPS_PORT:-8443}"

INSTALLER_DIR="${INSTALLER_DIR:-/opt/imc-installer}"
IMC_BIN="${IMC_BIN:-}"

if [[ -z "${IMC_BIN}" ]]; then
  mapfile -t bins < <(find "${INSTALLER_DIR}" -maxdepth 1 -type f -name "*.bin" | sort)
  [[ ${#bins[@]} -ge 1 ]] || fail "Nessun file .bin trovato in ${INSTALLER_DIR}"
  IMC_BIN="${bins[0]}"
fi

[[ -f "${IMC_BIN}" ]] || fail "Installer non trovato: ${IMC_BIN}"

log "Verifico dipendenze principali..."
rpm -q libnsl libXext libXtst libaio glibc mariadb-server >/dev/null || \
  fail "Dipendenze mancanti. Esegui prima gli script 01 e 02."

log "Installer trovato: ${IMC_BIN}"
chmod +x "${IMC_BIN}"

cat <<EOF

============================================================
INSTALLAZIONE HPE IMC

Server:
  Hostname FQDN : ${HOSTNAME_FQDN}
  IP            : ${SERVER_IP}

Database:
  DB type       : MySQL
  Host          : ${DB_HOST}
  Database      : ${DB_NAME}
  User          : ${DB_USER}
  Password      : ${DB_PASS}

Porte suggerite:
  HTTP          : ${HTTP_PORT}
  HTTPS         : ${HTTPS_PORT}

URL finale atteso:
  http://${SERVER_IP}:${HTTP_PORT}/imc
  https://${HOSTNAME_FQDN}:${HTTPS_PORT}/imc

NOTA:
- Questo script avvia il wizard IMC
- Completa i campi con i valori sopra
============================================================

EOF

sleep 3

log "Avvio installer IMC..."
"${IMC_BIN}"
