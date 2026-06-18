#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/common.sh"
source "$ROOT/scripts/toolchains.sh"

ENGINE="$1"           # e.g., caissa
PLATFORM="${2:-linux-x86_64}"
VERSION="${3:-}"
ENGINE_DIR="$ENGINE"
STOCKFISH_VERSION=""

if [[ "$ENGINE" =~ ^stockfish-(16|17|18)$ ]]; then
  ENGINE_DIR="stockfish"
  STOCKFISH_VERSION="${BASH_REMATCH[1]}"
fi

YAML="$ROOT/engines/$ENGINE_DIR/engine.yaml"
[[ -f "$YAML" ]] || { echo "Missing $YAML"; exit 1; }

if [[ -n "$VERSION" ]]; then
  OUTDIR="$ROOT/out/$VERSION/$PLATFORM/$ENGINE"
else
  OUTDIR="$ROOT/out/current/$ENGINE/$PLATFORM"
fi
SRCDIR="$WORK/src/$ENGINE"
LOGDIR="$WORK/logs/$ENGINE/$PLATFORM"
mkdir -p "$OUTDIR" "$LOGDIR"

if [[ -f "$ROOT/engines/$ENGINE_DIR/Makefile" ]]; then
  case "$PLATFORM" in
    linux-*) target="linux" ;;
    macos-silicon) target="macos-silicon" ;;
    windows-*) target="windows" ;;
    *) echo "Unsupported Makefile platform: $PLATFORM" >&2; exit 2 ;;
  esac

  if ! make -C "$ROOT/engines/$ENGINE_DIR" -n "$target" OUT="$OUTDIR" >/dev/null 2>&1; then
    echo "Engine $ENGINE does not define a Makefile target for $PLATFORM ($target)" >&2
    exit 4
  fi

  log "Building $ENGINE for $PLATFORM with engine Makefile ..."
  if ! {
    make -C "$ROOT/engines/$ENGINE_DIR" clean OUT="$OUTDIR" || true
    if [[ -n "$STOCKFISH_VERSION" ]]; then
      make -C "$ROOT/engines/$ENGINE_DIR" "$target" OUT="$OUTDIR" STOCKFISH_ONLY="$STOCKFISH_VERSION"
    else
      make -C "$ROOT/engines/$ENGINE_DIR" "$target" OUT="$OUTDIR"
    fi
  } >"$LOGDIR/build.log" 2>&1; then
    echo "Build failed for $ENGINE/$PLATFORM. Last build log lines:" >&2
    tail -n 200 "$LOGDIR/build.log" >&2 || true
    exit 1
  fi
  if [[ -n "$STOCKFISH_VERSION" ]]; then
    case "$PLATFORM" in
      linux-x86_64) stockfish_suffix="linux-x86_64" ;;
      macos-silicon) stockfish_suffix="macos-arm64" ;;
      windows-x86_64) stockfish_suffix="windows-x86_64.exe" ;;
      *) echo "Unsupported Stockfish platform: $PLATFORM" >&2; exit 2 ;;
    esac
    stockfish_engine="$ENGINE-$stockfish_suffix"
    ruby -ryaml -e '
      data = YAML.load_file(ARGV[0])
      version = ARGV[1]
      platform = ARGV[2]
      engine = ARGV[3]
      data["id"] = "stockfish-#{version}"
      data["name"] = "Stockfish #{version}"
      data["version"] = version == "16" ? "16.1" : version
      data["engine"] = engine
      data["platforms"] = { platform => { "engine" => engine } }
      File.write(ARGV[4], data.to_yaml)
    ' "$YAML" "$STOCKFISH_VERSION" "$PLATFORM" "$stockfish_engine" "$OUTDIR/engine.yaml"
  else
    cp "$YAML" "$OUTDIR/engine.yaml"
  fi
  log "Done: $OUTDIR"
  exit 0
fi

name=$(yq '.name' "$YAML")
system=$(yq '.build.system // "make"' "$YAML")
url=$(yq '.source.url // .source_repo' "$YAML")
ref=$(yq '.source.ref // .version // "main"' "$YAML")
stype=$(yq '.source.type // "git"' "$YAML")
binary=$(yq '.binary_name // .engine' "$YAML")

use_toolchain "$PLATFORM"
log "Fetching $ENGINE ($ref) ..."
case "$stype" in
  git) fetch_git "$url" "$SRCDIR" "$ref" ;;
  tar) fetch_tar "$url" "$SRCDIR" ;;
  external)
    cat > "$OUTDIR/UPSTREAM_DOWNLOAD.txt" <<TXT
$ENGINE is distributed upstream and is not built in this repository.
Download: $url
TXT
    cp "$YAML" "$OUTDIR/engine.yaml"
    log "Done: $OUTDIR"
    exit 0
    ;;
  *) echo "unknown source.type"; exit 2;;
esac

apply_patches "$SRCDIR" "$ROOT/engines/$ENGINE/patches" || true

log "Building $ENGINE for $PLATFORM ..."
case "$system" in
  make)
    { build_with_make "$SRCDIR" "$SRCDIR/build" "$(yq '.build.make_args // ""' "$YAML")"; } \
      >"$LOGDIR/build.log" 2>&1
    ;;
  cmake)
    { build_with_cmake "$SRCDIR" "$SRCDIR/build" "$(yq '.build.cmake_args // ""' "$YAML")"; } \
      >"$LOGDIR/build.log" 2>&1
    ;;
  *)
    echo "Unknown build.system=$system"; exit 2;;
esac

# Find the binary
BINPATH="$(fd -HI "$binary(.exe)?" "$SRCDIR" | head -n1)"
[[ -n "$BINPATH" ]] || { echo "Binary $binary not found"; exit 3; }

# Strip (if possible) and copy
cp "$BINPATH" "$OUTDIR/$binary$( [[ "$PLATFORM" == windows-* ]] && echo '.exe' )"
command -v $STRIP >/dev/null 2>&1 && $STRIP "$OUTDIR/"*
cp "$YAML" "$OUTDIR/engine.yaml"

log "Done: $OUTDIR"
