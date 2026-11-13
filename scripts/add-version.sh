#!/usr/bin/env bash
# Usage: nix run .#add-version -- <version>   e.g. 42.6   (or run directly with jq, git and nix on PATH)
# Prefetches the release tarball and adds its hash to versions.json (newest first).
set -euo pipefail
v=${1:?version required}
cd "$(git rev-parse --show-toplevel)"
jq -e --arg v "$v" 'has($v)' versions.json >/dev/null && { echo "$v already present" >&2; exit 1; }
hash=$(nix store prefetch-file --json \
  "https://github.com/deephaven/deephaven-core/releases/download/v$v/server-jetty-$v.tar" | jq -r .hash)
tmp=$(mktemp)
jq --arg v "$v" --arg h "$hash" '{($v): $h} + .' versions.json > "$tmp" && mv "$tmp" versions.json
echo "added $v = $hash"
