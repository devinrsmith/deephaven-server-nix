#!/usr/bin/env bash
# Usage: scripts/add-version.sh <version>   e.g. 42.6
# Prefetches the release tarball and inserts its hash into versions.nix.
set -euo pipefail
v=${1:?version required}
cd "$(dirname "$0")/.."
grep -q "\"$v\"" versions.nix && { echo "$v already present" >&2; exit 1; }
hash=$(nix store prefetch-file --json \
  "https://github.com/deephaven/deephaven-core/releases/download/v$v/server-jetty-$v.tar" | jq -r .hash)
sed -i "\$i\\  \"$v\" = \"$hash\";" versions.nix
echo "added $v = $hash"
