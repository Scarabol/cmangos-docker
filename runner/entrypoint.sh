#!/usr/bin/env bash
#

set -e

# Utils:
#
function _replace_conf()
{
    local SEARCH_FOR="${1}"
    local REPLACE_WITH="${2}"
    local FILENAME="${3}"

    sed -i "/^${SEARCH_FOR}/c\\${SEARCH_FOR} = ${REPLACE_WITH}" "${FILENAME}"
}

# Sub-functions:
#
function compose_mangosd_conf()
{
    local MANGOS_DBCONN="${MANGOS_DBHOST};${MANGOS_DBPORT};${MANGOS_DBUSER};${MANGOS_DBPASS}"

    cd "${MANGOS_DIR}/etc"

    _replace_conf "LoginDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_REALMD_DBNAME}\"" mangosd.conf
    _replace_conf "WorldDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_WORLD_DBNAME}\"" mangosd.conf
    _replace_conf "CharacterDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_CHARACTERS_DBNAME}\"" mangosd.conf
    _replace_conf "LogsDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_LOGS_DBNAME}\"" mangosd.conf
}
function compose_realmd_conf()
{
    local MANGOS_DBCONN="${MANGOS_DBHOST};${MANGOS_DBPORT};${MANGOS_DBUSER};${MANGOS_DBPASS}"

    cd "${MANGOS_DIR}/etc"

    _replace_conf "LoginDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_REALMD_DBNAME}\"" realmd.conf
}

function set_timezone()
{
    ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    echo "${TIMEZONE}" > /etc/timezone

    dpkg-reconfigure --frontend noninteractive tzdata &> /dev/null
}

function wait_for_database()
{
    wait-for-it -h "${MANGOS_DBHOST}" -p "${MANGOS_DBPORT}"
}

# Main functions:
#
function init_runner()
{
    set_timezone

    compose_mangosd_conf
    compose_realmd_conf
}

function run_mangosd()
{
    cd "${MANGOS_DIR}/bin"

    gosu mangos ./mangosd
}
function run_realmd()
{
    cd "${MANGOS_DIR}/bin"

    gosu mangos ./realmd
}

# Execution:
#
init_runner

case "${1}" in
    mangosd)
        shift

        wait_for_database
        run_mangosd ${@}
        ;;
    realmd)
        shift

        wait_for_database
        run_realmd ${@}
        ;;
    *)
        cd "${HOME_DIR}"

        exec ${@}
        ;;
esac

exit 1
