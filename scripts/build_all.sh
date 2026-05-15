#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-v1.0.0}"
PLATFORM="${2:-linux-x86_64}"
OUTROOT="$ROOT/out/$VERSION/$PLATFORM"

ENGINES=()
while IFS= read -r engdir; do
  ENGINES+=("$(basename "$engdir")")
done < <(find "$ROOT/engines" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ ${#ENGINES[@]} -eq 0 ]]; then
  echo "No engine directories found under $ROOT/engines" >&2
  exit 1
fi

for engine in "${ENGINES[@]}"; do
  engdir="$ROOT/engines/$engine"
  yaml="$engdir/engine.yaml"

  if [[ ! -f "$yaml" ]]; then
    echo "Skipping $engine: missing engine.yaml"
    continue
  fi

  echo "==> Building $engine for $PLATFORM"
  if bash "$ROOT/scripts/build_one.sh" "$engine" "$PLATFORM" "$VERSION"; then
    :
  else
    status=$?
    if [[ "$status" -eq 4 ]]; then
      echo "Skipping $engine for $PLATFORM: unsupported platform target"
      continue
    fi
    exit "$status"
  fi
done

echo "Processed ${#ENGINES[@]} engine(s) into $OUTROOT"
