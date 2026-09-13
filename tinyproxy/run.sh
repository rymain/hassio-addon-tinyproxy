#!/bin/sh
# Entrypoint (PID 1). Reads /data/options.json, writes a Tinyproxy config,
# then execs tinyproxy in the foreground. No bashio, no s6, no Supervisor API.
set -eu

OPTIONS=/data/options.json
CONF=/tmp/tinyproxy.conf

log() { echo "[$(date '+%H:%M:%S')] $*"; }
fatal() { echo "[$(date '+%H:%M:%S')] FATAL: $*" >&2; exit 1; }

[ -f "${OPTIONS}" ] || fatal "${OPTIONS} not found. Is this running as a Home Assistant add-on?"

opt() { jq -r --arg d "$2" ".${1} // \$d" "${OPTIONS}"; }

port=$(opt port 8888)
timeout=$(opt timeout 600)
log_level=$(opt log_level Info)
username=$(opt basic_auth_username "")
password=$(opt basic_auth_password "")

if [ -z "${username}" ] && [ -n "${password}" ]; then
    fatal "basic_auth_password is set but basic_auth_username is empty. Set both or neither; refusing to start."
fi
if [ -n "${username}" ] && [ -z "${password}" ]; then
    fatal "basic_auth_username is set but basic_auth_password is empty. Set both or neither; refusing to start."
fi

allow=$(jq -r '(.allow // [])[]' "${OPTIONS}")
[ -n "${allow}" ] || fatal "The 'allow' list is empty. Refusing to start an unrestricted proxy."

connect_ports=$(jq -r '(.connect_ports // [443,563])[]' "${OPTIONS}")

umask 077
{
    echo "User tinyproxy"
    echo "Group tinyproxy"
    echo "Port ${port}"
    echo "Timeout ${timeout}"
    echo "LogLevel ${log_level}"
    echo "MaxClients 50"
    echo "ViaProxyName \"tinyproxy\""
} > "${CONF}"

for cidr in ${allow}; do
    case "${cidr}" in
        0.0.0.0/0|::/0) fatal "Refusing '${cidr}' in the allow list: that is an open proxy." ;;
    esac
    echo "Allow ${cidr}" >> "${CONF}"
    log "Allowing ${cidr}"
done

for cport in ${connect_ports}; do
    echo "ConnectPort ${cport}" >> "${CONF}"
done
log "CONNECT allowed on ports: $(echo "${connect_ports}" | tr '\n' ' ')"

if [ -n "${username}" ]; then
    # Credentials go straight into the 0600 config file; never logged.
    echo "BasicAuth ${username} ${password}" >> "${CONF}"
    log "BasicAuth enabled for user '${username}'"
else
    log "WARNING: BasicAuth disabled; access restricted by the allow list only."
fi

log "Starting Tinyproxy on port ${port}"
exec tinyproxy -d -c "${CONF}"
