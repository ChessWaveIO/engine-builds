#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ENGINE="$1"
PLATFORM="$2"
OUT="$3"
YAML="$ROOT/engines/$ENGINE/engine.yaml"

[[ -f "$YAML" ]] || { echo "Missing $YAML" >&2; exit 1; }

read_yaml() {
  local expr="$1"
  ruby -ryaml -e '
    data = YAML.load_file(ARGV[0])
    expr = ARGV[1].split(".")
    value = expr.reduce(data) { |memo, key| memo.is_a?(Hash) ? memo[key] : nil }
    print(value) unless value.nil?
  ' "$YAML" "$expr"
}

asset_url="$(read_yaml "release_assets.$PLATFORM.url")"
asset_sha256="$(read_yaml "release_assets.$PLATFORM.sha256")"
asset_path="$(read_yaml "release_assets.$PLATFORM.path")"
binary_name="$(read_yaml "platforms.$PLATFORM.engine")"
license_url="$(read_yaml "compliance.license_url")"
source_ref="$(read_yaml "compliance.source_ref")"

if [[ -z "$asset_url" || -z "$binary_name" ]]; then
  echo "Engine $ENGINE does not define a release asset for $PLATFORM" >&2
  exit 4
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$OUT"

archive_name="${asset_url##*/}"
archive_path="$tmp_dir/$archive_name"
curl -fsSL "$asset_url" -o "$archive_path"

if command -v sha256sum >/dev/null 2>&1; then
  actual_sha256="$(sha256sum "$archive_path" | awk '{print $1}')"
else
  actual_sha256="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
fi
if [[ -n "$asset_sha256" && "$actual_sha256" != "$asset_sha256" ]]; then
  echo "SHA256 mismatch for $asset_url" >&2
  echo "expected: $asset_sha256" >&2
  echo "actual:   $actual_sha256" >&2
  exit 1
fi

case "$archive_name" in
  *.tar.gz|*.tgz) tar -xzf "$archive_path" -C "$tmp_dir" ;;
  *.tar.xz) tar -xJf "$archive_path" -C "$tmp_dir" ;;
  *.tar) tar -xf "$archive_path" -C "$tmp_dir" ;;
  *.zip) unzip -q "$archive_path" -d "$tmp_dir" ;;
  *.exe) direct_asset=1 ;;
  *) direct_asset=1 ;;
esac

if [[ -n "$asset_path" ]]; then
  src="$tmp_dir/$asset_path"
elif [[ "${direct_asset:-0}" == "1" ]]; then
  src="$archive_path"
else
  if [[ "$binary_name" == *.exe ]]; then
    src="$(find "$tmp_dir" -type f -iname '*.exe' | head -n1)"
  else
    src="$(find "$tmp_dir" -type f -perm -111 ! -name "$archive_name" | head -n1)"
    [[ -n "$src" ]] || src="$(find "$tmp_dir" -type f ! -name "$archive_name" | head -n1)"
  fi
fi

[[ -n "${src:-}" && -f "$src" ]] || { echo "No binary found for $ENGINE/$PLATFORM" >&2; exit 1; }
cp "$src" "$OUT/$binary_name"
chmod 0755 "$OUT/$binary_name"

if [[ -n "$license_url" ]]; then
  curl -fsSL "$license_url" -o "$OUT/LICENSE" || true
fi

cat > "$OUT/UPSTREAM.txt" <<TXT
Engine: $ENGINE
Platform: $PLATFORM
Source ref: $source_ref
Asset: $asset_url
Asset SHA256: $actual_sha256
TXT
