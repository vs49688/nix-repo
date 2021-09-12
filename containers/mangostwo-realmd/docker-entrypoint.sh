#!/bin/sh
set -e

[ -z "$DB_HOST" ] && export DB_HOST="127.0.0.1"
[ -z "$DB_USER" ] && export DB_USER="realmd"
[ -z "$DB_PASS" ] && export DB_PASS="realmd"
[ -z "$DB_PORT" ] && export DB_PORT="3306"
[ -z "$DB_NAME" ] && export DB_NAME="realmd"

[ -z "$REALMD_CONFIG_PATH" ] && export REALMD_CONFIG_PATH="/config/realmd.conf"
[ -z "$REALMD_PORT"        ] && export REALMD_PORT=3724
[ -z "$REALMD_BIND_IP"     ] && export REALMD_BIND_IP="0.0.0.0"
[ -z "$REALMD_LOG_LEVEL"   ] && export REALMD_LOG_LEVEL=0

##
# Generate realmd.conf if needed
##
if [ ! -f "$REALMD_CONFIG_PATH" ]; then
    echo "[*] Generating $REALMD_CONFIG_PATH..."
    echo "[*]   DB_HOST            = $DB_HOST"
    echo "[*]   DB_USER            = $DB_USER"
    echo "[*]   DB_PASS            = <hidden>"
    echo "[*]   DB_PORT            = $DB_PORT"
    echo "[*]   DB_NAME            = $DB_NAME"
    echo "[*]   REALMD_CONFIG_PATH = $REALMD_CONFIG_PATH"
    echo "[*]   REALMD_PORT        = $REALMD_PORT"
    echo "[*]   REALMD_BIND_IP     = $REALMD_BIND_IP"
    echo "[*]   REALMD_LOG_LEVEL   = $REALMD_LOG_LEVEL"

    cat <<EOF > "$REALMD_CONFIG_PATH"
[RealmdConf]
ConfVersion       = 2021010100

LoginDatabaseInfo = $DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;$DB_NAME
PidFile           = ""
RealmServerPort   = $REALMD_PORT
BindIP            = $REALMD_BIND_IP

LogLevel          = $REALMD_LOG_LEVEL
LogFile           = ""
EOF
else
    echo "[*] Not generating $REALMD_CONFIG_PATH, file exists..."
fi

##
# Initialise the database
##
MARIADB="mariadb --host=$DB_HOST --user=$DB_USER --password=$DB_PASS --port=$DB_PORT -sN ${DB_NAME}"

if [ -z "$($MARIADB -e "SHOW TABLES LIKE 'db_version'")" ]; then
    echo "[*] No version table, initialising..."
    $MARIADB < /share/mangos/database/Realm/Setup/realmdLoadDB.sql
else
    echo "[*] Found version table, skipping initialisation..."
fi

REALM_VERSION=$($MARIADB -e "SELECT version FROM db_version ORDER BY "version" DESC LIMIT 0,1")

if [ "$REALM_VERSION" = "22" ]; then
    echo "[*] Database version 22, nothing to do..."
elif [ "$REALM_VERSION" = "21" ]; then
    echo "[*] Database version 21, upgrading to 22..."
    # Updates are idempotent, just run them all
    for i in /share/mangos/database/Realm/Updates/Rel21/*.sql; do
        echo "[*] $i"
        $MARIADB < "$i" > /dev/null
    done

    for i in /share/mangos/database/Realm/Updates/Rel22/*.sql; do
        echo "[*] $i"
        $MARIADB < "$i" > /dev/null
    done
else
    echo "[*] Unknown database version ${REALM_VERSION}, aborting..."
    exit 1
fi

##
# Add a dummy realm if none already
##
if [ "$($MARIADB -e "SELECT COUNT(id) FROM realmlist")" -eq 0 ]; then
    $MARIADB < /share/mangos/database/Tools/updateRealm.sql > /dev/null
fi

echo "[*] Exec'ing /bin/realmd"
exec /bin/realmd -c "$REALMD_CONFIG_PATH"
