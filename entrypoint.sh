#!/bin/sh
set -e
exec "$@"
frp -c ${FRP_CONFIG_FILE:-/etc/frp/frps.toml}