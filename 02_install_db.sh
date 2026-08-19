#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_NAME="02_install_db"
log(){ echo "[$SCRIPT_NAME] $*"; }
fail(){ echo "[$SCRIPT_NAME][ERROR] $*" >&2; exit 1; }
require_root(){ [[ ${EUID:-$(id -u)} -eq 0 ]] || fail "Esegui lo script come root."; }
sql_escape(){ printf '%s' "$1" | sed "s/'/''/g"; }
require_root
DB_NAME="${DB_NAME:-imc_db}"; DB_USER="${DB_USER:-imc}"; DB_PASS="${DB_PASS:-}"; DB_HOST="${DB_HOST:-localhost}"
DB_CHARSET="${DB_CHARSET:-utf8mb4}"; DB_COLLATION="${DB_COLLATION:-utf8mb4_general_ci}"; CRED_FILE="${CRED_FILE:-/root/imc-db.env}"
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || fail "DB_NAME non valido."
[[ "$DB_USER" =~ ^[A-Za-z0-9_]+$ ]] || fail "DB_USER non valido."
[[ "$DB_HOST" =~ ^[A-Za-z0-9_.:%-]+$ ]] || fail "DB_HOST non valido."
[[ "$DB_CHARSET" =~ ^[A-Za-z0-9_]+$ ]] || fail "DB_CHARSET non valido."
[[ "$DB_COLLATION" =~ ^[A-Za-z0-9_]+$ ]] || fail "DB_COLLATION non valido."
if [[ -z "$DB_PASS" ]]; then command -v openssl >/dev/null 2>&1 || dnf -y install openssl; DB_PASS="$(openssl rand -base64 24 | tr -d '\n')"; log "Generata una password DB casuale."; fi
DB_PASS_SQL="$(sql_escape "$DB_PASS")"
log "Installo MariaDB server..."; dnf -y install mariadb-server; systemctl enable --now mariadb
log "Attendo MariaDB..."; for _ in {1..30}; do mysqladmin ping --silent >/dev/null 2>&1 && break; sleep 2; done
mysqladmin ping --silent >/dev/null 2>&1 || fail "MariaDB non risponde."
log "Creo/aggiorno database e utente IMC..."
mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET ${DB_CHARSET} DEFAULT COLLATE ${DB_COLLATION};
CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS_SQL}';
ALTER USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS_SQL}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'${DB_HOST}';
FLUSH PRIVILEGES;
SQL
umask 077
{ printf 'DB_NAME=%q\n' "$DB_NAME"; printf 'DB_USER=%q\n' "$DB_USER"; printf 'DB_PASS=%q\n' "$DB_PASS"; printf 'DB_HOST=%q\n' "$DB_HOST"; } > "$CRED_FILE"
chmod 0600 "$CRED_FILE"
log "Verifico database e utente..."; mysql -e "SHOW DATABASES LIKE '${DB_NAME}';"; mysql -e "SELECT user, host FROM mysql.user WHERE user='${DB_USER}';"
cat <<EOF

[OK] Database pronto per IMC.
Credenziali salvate in: ${CRED_FILE} (permessi 0600)
DB type : MySQL/MariaDB
Host    : ${DB_HOST}
DB name : ${DB_NAME}
User    : ${DB_USER}

Lo script 03 legge automaticamente ${CRED_FILE} se DB_PASS non è già impostata.
EOF
