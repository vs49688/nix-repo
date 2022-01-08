#!/bin/sh

[ -z "$MANGOSD_CONFIG_PATH" ]    && export MANGOSD_CONFIG_PATH="/config/mangosd.conf"
[ -z "$MANGOSD_CONFIG_PORT" ]    && export MANGOSD_CONFIG_PORT=8085
[ -z "$MANGOSD_CONFIG_BIND_IP" ] && export MANGOSD_CONFIG_BIND_IP=0.0.0.0

[ -z "$MANGOSD_LOGIN_DB_HOST" ] && export MANGOSD_LOGIN_DB_HOST=127.0.0.1
[ -z "$MANGOSD_LOGIN_DB_USER" ] && export MANGOSD_LOGIN_DB_USER=mangos
[ -z "$MANGOSD_LOGIN_DB_PASS" ] && export MANGOSD_LOGIN_DB_PASS=mangos
[ -z "$MANGOSD_LOGIN_DB_PORT" ] && export MANGOSD_LOGIN_DB_PORT=3306
[ -z "$MANGOSD_LOGIN_DB_NAME" ] && export MANGOSD_LOGIN_DB_NAME=realmd

[ -z "$MANGOSD_WORLD_DB_HOST" ] && export MANGOSD_WORLD_DB_HOST=127.0.0.1
[ -z "$MANGOSD_WORLD_DB_USER" ] && export MANGOSD_WORLD_DB_USER=mangos
[ -z "$MANGOSD_WORLD_DB_PASS" ] && export MANGOSD_WORLD_DB_PASS=mangos
[ -z "$MANGOSD_WORLD_DB_PORT" ] && export MANGOSD_WORLD_DB_PORT=3306
[ -z "$MANGOSD_WORLD_DB_NAME" ] && export MANGOSD_WORLD_DB_NAME=mangos2

[ -z "$MANGOSD_CHAR_DB_HOST" ]  && export MANGOSD_CHAR_DB_HOST=127.0.0.1
[ -z "$MANGOSD_CHAR_DB_USER" ]  && export MANGOSD_CHAR_DB_USER=mangos
[ -z "$MANGOSD_CHAR_DB_PASS" ]  && export MANGOSD_CHAR_DB_PASS=mangos
[ -z "$MANGOSD_CHAR_DB_PORT" ]  && export MANGOSD_CHAR_DB_PORT=3306
[ -z "$MANGOSD_CHAR_DB_NAME" ]  && export MANGOSD_CHAR_DB_NAME=character2


# Put any default overrides go here
[ -z "$MANGOSD_CONF_RealmID" ]       && export MANGOSD_CONF_RealmID=1
[ -z "$MANGOSD_CONF_DataDir" ]       && export MANGOSD_CONF_DataDir=/data
[ -z "$MANGOSD_CONF_LogFile" ]       && export MANGOSD_CONF_LogFile=
[ -z "$MANGOSD_CONF_Ra__Enable" ]    && export MANGOSD_CONF_Ra__Enable=1
[ -z "$MANGOSD_CONF_Ra__IP" ]        && export MANGOSD_CONF_Ra__IP=127.0.0.1
[ -z "$MANGOSD_CONF_Ra__Port" ]      && export MANGOSD_CONF_Ra__Port=3443
[ -z "$MANGOSD_CONF_SOAP__Enabled" ] && export MANGOSD_CONF_SOAP__Enabled=1
[ -z "$MANGOSD_CONF_SOAP__IP" ]      && export MANGOSD_CONF_SOAP__IP=127.0.0.1
[ -z "$MANGOSD_CONF_SOAP_Port" ]     && export MANGOSD_CONF_SOAP__Port=7878

# Unset any MANGOSD_CONF_* vars we don't want overridden
unset \
    MANGOSD_CONF_ConfVersion \
    MANGOSD_CONF_PidFile \
    MANGOSD_CONF_BindIP \
    MANGOSD_CONF_WorldServerPort \
    MANGOSD_CONF_LoginDatabaseInfo \
    MANGOSD_CONF_WorldDatabaseInfo \
    MANGOSD_CONF_CharacterDatabaseInfo \
    MANGOSD_CONF_Console__Enable

if [ ! -f "$MANGOSD_CONFIG_PATH" ]; then
    echo "[*] Generating $MANGOSD_CONFIG_PATH..."

    ##
    # Convert environment vars of the form "MANGOSD_CONF_XXXX=YYYY"
    # into "XXXX = YYYYY" in mangos.conf. If YYYY is empty, it is surrounded
    # by empty quotes. For a period, use two underscores (__)
    # Honestly, I feel kind of dirty...
    ##
    envconf=$(env | awk -F= '{ $2 = substr($0, index($0, "=") + 1); if ($1 ~ /^MANGOSD_CONF_/) { gsub(/^MANGOSD_CONF_/, "", $1); gsub(/__/, ".", $1); val = ($2 == "") ? "\"\"" : $2; printf "%s = %s\n", $1, val; } }' | sort)

    cat <<EOF > "$MANGOSD_CONFIG_PATH"
# See https://github.com/mangos/mangosd/blob/master/mangos2.conf.dist.in
[MangosdConf]
ConfVersion           = 2021010100
BindIP                = "${MANGOSD_CONFIG_BIND_IP}"
WorldServerPort       = $MANGOSD_CONFIG_PORT
LoginDatabaseInfo     = "$MANGOSD_LOGIN_DB_HOST;$MANGOSD_LOGIN_DB_PORT;$MANGOSD_LOGIN_DB_USER;$MANGOSD_LOGIN_DB_PASS;$MANGOSD_LOGIN_DB_NAME"
WorldDatabaseInfo     = "$MANGOSD_WORLD_DB_HOST;$MANGOSD_WORLD_DB_PORT;$MANGOSD_WORLD_DB_USER;$MANGOSD_WORLD_DB_PASS;$MANGOSD_WORLD_DB_NAME"
CharacterDatabaseInfo = "$MANGOSD_CHAR_DB_HOST;$MANGOSD_CHAR_DB_PORT;$MANGOSD_CHAR_DB_USER;$MANGOSD_CHAR_DB_PASS;$MANGOSD_CHAR_DB_NAME"

##
# Force disable the console, as a closed stdin will terminate the server
# Use RA.Enable (via telnet) or SOAP.Enabled
##
Console.Enable = 0

##
# Begin Custom Properties
##
EOF
    printf "%s\n" "$envconf" >> "$MANGOSD_CONFIG_PATH"
else
    echo "[*] Not generating $MANGOSD_CONFIG_PATH, file exists..."
fi

##
# Initialise the character database
##
MARIADB="mariadb --host=$MANGOSD_CHAR_DB_HOST --user=$MANGOSD_CHAR_DB_USER --password=$MANGOSD_CHAR_DB_PASS --port=$MANGOSD_CHAR_DB_PORT -sN ${MANGOSD_CHAR_DB_NAME}"

if [ -z "$($MARIADB -e "SHOW TABLES LIKE 'db_version'")" ]; then
    echo "[*] Character: No version table, initialising..."
    $MARIADB < /share/mangos/database/Character/Setup/characterLoadDB.sql
else
    echo "[*] Character: Found version table, skipping initialisation..."
fi

CHAR_VERSION=$($MARIADB -e "SELECT CONCAT(version,'.',structure,'.',content) FROM db_version ORDER BY "version" DESC LIMIT 0,1")

echo "[*] Character: Version ${CHAR_VERSION}, running migrations..."
for i in /share/mangos/database/Character/Updates/Rel??/*.sql; do
    echo "[*] $i"
    $MARIADB < "$i" > /dev/null
done

##
# Initialise the world database
##
MARIADB="mariadb --host=$MANGOSD_WORLD_DB_HOST --user=$MANGOSD_WORLD_DB_USER --password=$MANGOSD_WORLD_DB_PASS --port=$MANGOSD_WORLD_DB_PORT -sN ${MANGOSD_WORLD_DB_NAME}"

if [ -z "$($MARIADB -e "SHOW TABLES LIKE 'db_version'")" ]; then
    echo "[*] World: No version table, initialising..."
    $MARIADB < /share/mangos/database/World/Setup/mangosdLoadDB.sql

    for i in /share/mangos/database/World/Setup/FullDB/*.sql; do
        echo "[*] $i"
        $MARIADB < "$i" > /dev/null
    done
else
    echo "[*] World: Found version table, skipping initialisation..."
fi

WORLD_VERSION=$($MARIADB -e "SELECT CONCAT(version,'.',structure,'.',content) FROM db_version ORDER BY "version" DESC LIMIT 0,1")

echo "[*] World: Version ${WORLD_VERSION}, running migrations..."
for i in /share/mangos/database/World/Updates/Rel??/*.sql; do
    echo "[*] $i"
    $MARIADB < "$i" > /dev/null
done

echo "[*] Exec'ing /bin/mangosd"
exec /bin/mangosd -c "$MANGOSD_CONFIG_PATH"
