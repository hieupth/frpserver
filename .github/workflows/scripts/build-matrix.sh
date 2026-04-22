#!/bin/bash
# Generate GitHub Actions build matrix for frp Docker images.
#
# This script:
#   1. Fetches releases from fatedier/frp GitHub API
#   2. Filters out prereleases and versions below a minimum threshold
#   3. Outputs a JSON matrix for GitHub Actions strategy
#
# Usage:
#   ./build-matrix.sh                    # Latest release only (default)
#   ./build-matrix.sh --latest           # Latest release only
#   ./build-matrix.sh --all              # All releases >= minimum version
#   ./build-matrix.sh --from 0.60.0      # All releases >= 0.60.0
#
# Environment variables:
#   FROM_TAG   - Minimum version to build (overrides build.conf)
#   BUILD_MODE - "latest" or "all" (default: "latest")

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_URL="https://api.github.com/repos/fatedier/frp/releases?per_page=100"

# --- Configuration ---

BUILD_MODE="${BUILD_MODE:-latest}"

# Read minimum version from build.conf (skip comments and empty lines)
CONFIG_FROM_TAG=""
if [ -f "$SCRIPT_DIR/build.conf" ]; then
    CONFIG_FROM_TAG=$(sed '/^#/d; /^$/d' "$SCRIPT_DIR/build.conf" | head -1)
fi
FROM_TAG="${FROM_TAG:-$CONFIG_FROM_TAG}"

# Parse CLI arguments (override env vars)
while [ $# -gt 0 ]; do
    case "$1" in
        --latest) BUILD_MODE="latest"; shift ;;
        --all)    BUILD_MODE="all"; shift ;;
        --from)   FROM_TAG="$2"; shift 2 ;;
        *)        shift ;;
    esac
done

# --- Fetch releases from GitHub API ---
#
# The API returns releases sorted by created_at descending.
# We extract tag_name from each release, skip prereleases,
# and strip the 'v' prefix (e.g., "v0.68.0" → "0.68.0").

RAW_RELEASES=$(curl -s "$API_URL" | \
    perl -ne 'if (/"tag_name":\s*"v?([^"]+)"/) { $tag=$1 }
              if (/"prerelease":\s*false/ && $tag) { print "$tag\n"; $tag=undef }')

if [ -z "$RAW_RELEASES" ]; then
    echo "Error: Could not fetch frp releases from GitHub" >&2
    exit 1
fi

# Sort versions descending by semver (major.minor.patch)
SORTED_RELEASES=$(echo "$RAW_RELEASES" | sort -t. -k1,1nr -k2,2nr -k3,3nr)

# --- Filter by minimum version ---
#
# Convert a version string "X.Y.Z" to an integer X*1000000 + Y*1000 + Z
# so we can do simple arithmetic comparison.

tag_to_int() {
    local major minor patch
    IFS='.' read -r major minor patch <<< "$1"
    echo $((major * 1000000 + minor * 1000 + patch))
}

# Collect versions that meet the minimum threshold
declare -a TAGS=()
while read -r version; do
    if [ -n "$FROM_TAG" ]; then
        version_int=$(tag_to_int "$version")
        from_int=$(tag_to_int "$FROM_TAG")
        if [ "$version_int" -lt "$from_int" ]; then
            continue
        fi
    fi
    TAGS+=("$version")
done <<< "$SORTED_RELEASES"

if [ ${#TAGS[@]} -eq 0 ]; then
    echo "Error: No releases found >= $FROM_TAG" >&2
    exit 1
fi

# --- Generate JSON matrix ---
#
# Output format for GitHub Actions:
#   {"include":[{"tag":"0.68.0","version":"0.68.0","is_latest":true}]}
#
# The first (newest) version gets is_latest=true so the workflow
# can tag it as "latest" on Docker Hub.

if [ "$BUILD_MODE" = "latest" ]; then
    # Only the newest release
    echo "{\"include\":[{\"tag\":\"${TAGS[0]}\",\"version\":\"${TAGS[0]}\",\"is_latest\":true}]}"
else
    # All qualifying releases, newest first
    echo -n '{"include":['
    for i in "${!TAGS[@]}"; do
        [ "$i" -gt 0 ] && echo -n ','
        IS_LATEST="false"
        [ "$i" -eq 0 ] && IS_LATEST="true"
        echo -n "{\"tag\":\"${TAGS[$i]}\",\"version\":\"${TAGS[$i]}\",\"is_latest\":$IS_LATEST}"
    done
    echo ']}'
fi
