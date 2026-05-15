#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/.work"     # temp build area
mkdir -p "$WORK"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# ---- fetchers ----
fetch_git() {
  local url="$1" dest="$2" ref="$3"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" fetch --all --tags --prune
  else
    git clone --recursive "$url" "$dest"
  fi
  git -C "$dest" checkout --recurse-submodules "$ref"
  git -C "$dest" submodule update --init --recursive
}

fetch_tar() {
  local url="$1" dest="$2"
  mkdir -p "$dest"
  curl -L "$url" | tar -xz -C "$dest" --strip-components=1
}

apply_patches() {
  local src="$1" patch_dir="$2"
  [[ -d "$patch_dir" ]] || return 0
  for p in "$patch_dir"/*.patch; do
    [[ -e "$p" ]] || continue
    log "Applying patch $(basename "$p")"
    git -C "$src" apply --whitespace=fix "$p"
  done
}

# ---- build helpers ----
build_with_make() {
  local src="$1" builddir="$2" make_args="${3:-}"
  mkdir -p "$builddir"
  make -C "$src" -j"$(nproc)" $make_args
}

build_with_cmake() {
  local src="$1" builddir="$2" cmake_args="${3:-}" target="${4:-install}"
  mkdir -p "$builddir"
  cmake -S "$src" -B "$builddir" $cmake_args
  cmake --build "$builddir" --config Release -j"$(nproc)"
  [[ "$target" == "-" ]] || cmake --install "$builddir" --config Release
}

# ---- packaging helpers ----
archive_source_snapshot() {
  local src="$1" out_tar="$2"
  # include submodules & .git metadata via --prefix archive + .git dir for full provenance
  tar --exclude="$src/.work" \
      -czf "$out_tar" -C "$src" .
}

hash_file() {
  sha256sum "$1" | awk '{print $1}'
}

