#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_NAME="01_prep_os"
log(){ echo "[$SCRIPT_NAME] $*"; }
fail(){ echo "[$SCRIPT_NAME][ERROR] $*" >&2; exit 1; }
require_root(){ [[ ${EUID:-$(id -u)} -eq 0 ]] || fail "Esegui lo script come root."; }
backup_file(){ local file="$1"; [[ -f "$file" ]] && cp -a "$file" "${file}.bak.$(date +%F-%H%M%S)"; }
require_root
HOSTNAME_FQDN="${HOSTNAME_FQDN:-imc-hpe.aopro.it}"
EXPECTED_IP="${EXPECTED_IP:-10.10.0.5}"
LAB_MODE="${LAB_MODE:-0}"
log "Aggiorno il sistema..."; dnf -y update
log "Installo repository EPEL..."; dnf -y install epel-release
log "Installo pacchetti base e librerie di compatibilità..."
dnf -y install bash-completion curl wget unzip tar net-tools bind-utils lsof rsync vim nano policycoreutils-python-utils libnsl libXext libXtst libaio glibc hostname python3 openssl
log "Imposto hostname a ${HOSTNAME_FQDN}..."; hostnamectl set-hostname "$HOSTNAME_FQDN"
log "Aggiorno /etc/hosts..."; backup_file /etc/hosts
if grep -qE "[[:space:]]${HOSTNAME_FQDN//./\.}([[:space:]]|$)" /etc/hosts; then
  sed -ri "s|^.*[[:space:]]${HOSTNAME_FQDN//./\.}([[:space:]].*)?$|${EXPECTED_IP} ${HOSTNAME_FQDN} ${HOSTNAME_FQDN%%.*}|" /etc/hosts
else
  echo "${EXPECTED_IP} ${HOSTNAME_FQDN} ${HOSTNAME_FQDN%%.*}" >> /etc/hosts
fi
if [[ "$LAB_MODE" == "1" ]]; then
  log "LAB_MODE=1: disabilito SELinux e firewalld per compatibilità con ambienti di laboratorio IMC."
  setenforce 0 2>/dev/null || true
  if [[ -f /etc/selinux/config ]]; then backup_file /etc/selinux/config; sed -ri 's/^SELINUX=(enforcing|permissive)/SELINUX=disabled/' /etc/selinux/config; fi
  systemctl disable --now firewalld || true
else
  log "Mantengo SELinux e firewalld invariati. Per il vecchio comportamento lab usa LAB_MODE=1."
fi
install -d -m 0755 /opt/imc-installer /opt/imc-scripts
log "Verifica hostname e indirizzi..."; hostnamectl status; getent hosts "$HOSTNAME_FQDN" || true; ip -4 addr show | awk '/inet / {print $2}'
cat <<EOF

[OK] Preparazione OS completata.
Hostname impostato: ${HOSTNAME_FQDN}
IP atteso          : ${EXPECTED_IP}
LAB_MODE           : ${LAB_MODE}

Verifica che la VM abbia davvero l'IP atteso e riavvia prima di proseguire.
EOF
