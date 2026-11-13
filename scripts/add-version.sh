#!/usr/bin/env bash
# Usage: scripts/add-version.sh <version>   e.g. 42.6
# Prefetches the release tarball and adds its hash to versions.json (newest first).
set -euo pipefail
v=${1:?version required}
cd "$(dirname "$0")/.."
jq -e --arg v "$v" 'has($v)' versions.json >/dev/null && { echo "$v already present" >&2; exit 1; }
hash=$(nix store prefetch-file --json \
  "https://github.com/deephaven/deephaven-core/releases/download/v$v/server-jetty-$v.tar" | jq -r .hash)
tmp=$(mktemp)
jq --arg v "$v" --arg h "$hash" '{($v): $h} + .' versions.json > "$tmp" && mv "$tmp" versions.json
echo "added $v = $hash"
