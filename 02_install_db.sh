#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="02_install_db"

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

DB_NAME="${DB_NAME:-imc_db}"
DB_USER="${DB_USER:-imc}"
DB_PASS="${DB_PASS:-ChangeMe_Str0ng!}"
DB_HOST="${DB_HOST:-localhost}"
DB_CHARSET="${DB_CHARSET:-utf8}"
DB_COLLATION="${DB_COLLATION:-utf8_general_ci}"

log "Installo MariaDB server..."
dnf -y install mariadb-server

log "Abilito e avvio MariaDB..."
systemctl enable --now mariadb

log "Attendo che MariaDB sia disponibile..."
for i in {1..30}; do
  if mysqladmin ping --silent >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

mysqladmin ping --silent >/dev/null 2>&1 || fail "MariaDB non risponde."

log "Creo database e utente IMC..."
mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
  DEFAULT CHARACTER SET ${DB_CHARSET}
  DEFAULT COLLATE ${DB_COLLATION};

CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}'
  IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'${DB_HOST}';
FLUSH PRIVILEGES;
SQL

log "Verifico database..."
mysql -e "SHOW DATABASES LIKE '${DB_NAME}';"

log "Verifico utente..."
mysql -e "SELECT user, host FROM mysql.user WHERE user='${DB_USER}';"

cat <<EOF

[OK] Database pronto per IMC.

Parametri installer IMC:
  DB type : MySQL
  Host    : ${DB_HOST}
  DB name : ${DB_NAME}
  User    : ${DB_USER}
  Pass    : ${DB_PASS}

EOF
