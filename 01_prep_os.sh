#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="01_prep_os"

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

backup_file() {
  local file="$1"
  [[ -f "$file" ]] && cp -a "$file" "${file}.bak.$(date +%F-%H%M%S)"
}

require_root

HOSTNAME_FQDN="imc-hpe.aopro.it"
EXPECTED_IP="10.10.0.5"

log "Aggiorno il sistema..."
dnf -y update

log "Installo repository EPEL..."
dnf -y install epel-release

log "Installo pacchetti base e librerie compatibilità..."
dnf -y install \
  bash-completion \
  curl \
  wget \
  unzip \
  tar \
  net-tools \
  bind-utils \
  lsof \
  rsync \
  vim \
  nano \
  policycoreutils-python-utils \
  libnsl \
  libXext \
  libXtst \
  libaio \
  glibc \
  hostname \
  python3

log "Imposto hostname a ${HOSTNAME_FQDN}..."
hostnamectl set-hostname "${HOSTNAME_FQDN}"

log "Aggiorno /etc/hosts..."
backup_file /etc/hosts

if grep -qE "[[:space:]]${HOSTNAME_FQDN}([[:space:]]|$)" /etc/hosts; then
  sed -ri "s/^.*[[:space:]]${HOSTNAME_FQDN}(\s.*)?$/${EXPECTED_IP} ${HOSTNAME_FQDN} imc-hpe/" /etc/hosts
else
  echo "${EXPECTED_IP} ${HOSTNAME_FQDN} imc-hpe" >> /etc/hosts
fi

log "Disabilito SELinux runtime..."
setenforce 0 || true

log "Disabilito SELinux in modo permanente..."
if [[ -f /etc/selinux/config ]]; then
  backup_file /etc/selinux/config
  sed -ri 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
  sed -ri 's/^SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
fi

log "Disabilito firewalld (scenario lab/trial)..."
systemctl disable --now firewalld || true

log "Creo directory standard..."
mkdir -p /opt/imc-installer
mkdir -p /opt/imc-scripts
chmod 755 /opt/imc-installer /opt/imc-scripts

log "Verifica configurazione hostname..."
hostnamectl status

log "Verifica risoluzione hostname..."
getent hosts "${HOSTNAME_FQDN}" || true

log "Indirizzi IP rilevati:"
ip -4 addr show | awk '/inet / {print $2}'

cat <<EOF

[OK] Preparazione OS completata.

Hostname impostato: ${HOSTNAME_FQDN}
IP atteso          : ${EXPECTED_IP}

ATTENZIONE:
- verifica che la VM abbia davvero IP ${EXPECTED_IP}
- riavvia la VM prima di proseguire

EOF
