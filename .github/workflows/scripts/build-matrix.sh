#!/bin/bash
# Generate GitHub Actions matrix for building frp images
#
# Usage:
#   ./build-matrix.sh                    # All releases
#   ./build-matrix.sh --latest           # Only latest release
#   ./build-matrix.sh --from 0.60.0      # All releases >= 0.60.0
#
# Environment variables:
#   FROM_TAG   - Default: '' (all versions)
#   BUILD_MODE - "latest" or "all", default: "latest"

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
BUILD_MODE="${BUILD_MODE:-latest}"

# Read minimum version from config (skip comments and empty lines)
CONFIG_FROM_TAG=""
if [ -f "$SCRIPT_DIR/build.conf" ]; then
    CONFIG_FROM_TAG=$(sed '/^#/d; /^$/d' "$SCRIPT_DIR/build.conf" | head -1)
fi
FROM_TAG="${FROM_TAG:-$CONFIG_FROM_TAG}"

while [ $# -gt 0 ]; do
    case "$1" in
        --latest) BUILD_MODE="latest"; shift ;;
        --from) FROM_TAG="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Detect releases
if [ -n "$FROM_TAG" ]; then
    DETECT_OUTPUT=$("$SCRIPT_DIR/detect-frp.sh" --from "$FROM_TAG")
else
    DETECT_OUTPUT=$("$SCRIPT_DIR/detect-frp.sh")
fi

# Parse releases into arrays
declare -a TAGS VERSIONS

while IFS= read -r line; do
    TAG=$(echo "$line" | sed -n 's/.*TAG=\([^ ]*\).*/\1/p')
    VERSION=$(echo "$line" | sed -n 's/.*VERSION=\(.*\)/\1/p')
    TAGS+=("$TAG")
    VERSIONS+=("$VERSION")
done <<< "$DETECT_OUTPUT"

if [ ${#TAGS[@]} -eq 0 ]; then
    echo "Error: No releases found" >&2
    exit 1
fi

# Build matrix JSON
if [ "$BUILD_MODE" = "latest" ]; then
    echo "{\"include\":[{\"tag\":\"${TAGS[0]}\",\"version\":\"${VERSIONS[0]}\",\"is_latest\":true}]}"
else
    echo -n '{"include":['
    for i in "${!TAGS[@]}"; do
        [ $i -gt 0 ] && echo -n ','
        IS_LATEST="false"
        [ $i -eq 0 ] && IS_LATEST="true"
        echo -n "{\"tag\":\"${TAGS[$i]}\",\"version\":\"${VERSIONS[$i]}\",\"is_latest\":$IS_LATEST}"
    done
    echo ']}'
fi
