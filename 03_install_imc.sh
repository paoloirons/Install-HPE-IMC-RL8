#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_NAME="03_install_imc"
log(){ echo "[$SCRIPT_NAME] $*"; }
fail(){ echo "[$SCRIPT_NAME][ERROR] $*" >&2; exit 1; }
require_root(){ [[ ${EUID:-$(id -u)} -eq 0 ]] || fail "Esegui lo script come root."; }
require_root
CRED_FILE="${CRED_FILE:-/root/imc-db.env}"
if [[ -z "${DB_PASS:-}" && -r "$CRED_FILE" ]]; then source "$CRED_FILE"; fi
HOSTNAME_FQDN="${HOSTNAME_FQDN:-imc-hpe.aopro.it}"; SERVER_IP="${SERVER_IP:-10.10.0.5}"
DB_NAME="${DB_NAME:-imc_db}"; DB_USER="${DB_USER:-imc}"; DB_PASS="${DB_PASS:-}"; DB_HOST="${DB_HOST:-localhost}"
HTTP_PORT="${HTTP_PORT:-8080}"; HTTPS_PORT="${HTTPS_PORT:-8443}"; INSTALLER_DIR="${INSTALLER_DIR:-/opt/imc-installer}"; IMC_BIN="${IMC_BIN:-}"
[[ -n "$DB_PASS" ]] || fail "DB_PASS non disponibile. Esegui 02_install_db.sh o imposta DB_PASS."
if [[ -z "$IMC_BIN" ]]; then mapfile -t bins < <(find "$INSTALLER_DIR" -maxdepth 1 -type f -name '*.bin' | sort); [[ ${#bins[@]} -ge 1 ]] || fail "Nessun file .bin trovato in ${INSTALLER_DIR}"; [[ ${#bins[@]} -eq 1 ]] || fail "Trovati più installer .bin: imposta IMC_BIN esplicitamente."; IMC_BIN="${bins[0]}"; fi
[[ -f "$IMC_BIN" ]] || fail "Installer non trovato: $IMC_BIN"
rpm -q libnsl libXext libXtst libaio glibc mariadb-server >/dev/null || fail "Dipendenze mancanti. Esegui prima 01 e 02."
chmod +x "$IMC_BIN"
cat <<EOF

============================================================
INSTALLAZIONE HPE IMC
Server: ${HOSTNAME_FQDN} (${SERVER_IP})
Database: ${DB_HOST} / ${DB_NAME} / ${DB_USER}
Password DB: ${DB_PASS}
Porte suggerite: HTTP ${HTTP_PORT}, HTTPS ${HTTPS_PORT}
URL atteso: http://${SERVER_IP}:${HTTP_PORT}/imc
============================================================

EOF
log "Avvio installer IMC: ${IMC_BIN}"; "$IMC_BIN"
