#!/bin/bash
# Detect frp releases from GitHub
# - Fetches releases from fatedier/frp
# - Filters out prereleases
# - Strips 'v' prefix from tags
#
# Usage:
#   ./detect-frp.sh                     # Print all releases
#   ./detect-frp.sh --latest            # Print only latest
#   ./detect-frp.sh --from TAG          # Print releases >= TAG

set -e

API_URL="https://api.github.com/repos/fatedier/frp/releases?per_page=100"

# Parse arguments
MODE="all"
FROM_TAG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --latest)
            MODE="latest"
            shift
            ;;
        --from)
            FROM_TAG="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Fetch all releases, filter out prereleases, extract tag_names, strip 'v' prefix
RELEASES=$(curl -s "$API_URL" | perl -ne 'if (/"tag_name":\s*"v?([^"]+)"/) { $tag=$1 } if (/"prerelease":\s*false/ && $tag) { print "$tag\n"; $tag=undef }')

if [ -z "$RELEASES" ]; then
    echo "Error: Could not fetch frp releases" >&2
    exit 1
fi

# Sort versions descending (semver: major.minor.patch)
SORTED_RELEASES=$(echo "$RELEASES" | sort -t. -k1,1nr -k2,2nr -k3,3nr)

# Convert tag to comparable integer (major*1000000 + minor*1000 + patch)
tag_to_int() {
    local major minor patch
    IFS='.' read -r major minor patch <<< "$1"
    echo $((major * 1000000 + minor * 1000 + patch))
}

# Handle output mode
case "$MODE" in
    latest)
        version=$(echo "$SORTED_RELEASES" | head -1)
        if [ -n "$FROM_TAG" ]; then
            latest_int=$(tag_to_int "$version")
            from_int=$(tag_to_int "$FROM_TAG")
            if [ "$latest_int" -lt "$from_int" ]; then
                echo "Error: Latest tag $version is older than --from $FROM_TAG" >&2
                exit 1
            fi
        fi
        echo "TAG=$version"
        echo "VERSION=$version"
        ;;
    *)
        if [ -n "$FROM_TAG" ]; then
            from_int=$(tag_to_int "$FROM_TAG")
        fi

        echo "$SORTED_RELEASES" | while read -r version; do
            if [ -n "$FROM_TAG" ]; then
                tag_int=$(tag_to_int "$version")
                if [ "$tag_int" -lt "$from_int" ]; then
                    continue
                fi
            fi
            echo "TAG=$version VERSION=$version"
        done
        ;;
esac
