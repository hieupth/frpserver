#!/bin/sh
set -e
exec frp -c ${CONFIG_FILE:-/etc/frp/config.toml}
