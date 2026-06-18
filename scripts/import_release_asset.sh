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

read_extra_paths() {
  ruby -ryaml -e '
    data = YAML.load_file(ARGV[0])
    platform = ARGV[1]
    extras = data.dig("release_assets", platform, "extra_paths") || []
    extras.each do |entry|
      if entry.is_a?(Hash)
        path = entry["path"]
        name = entry["name"] || File.basename(path.to_s)
      else
        path = entry
        name = File.basename(path.to_s)
      end
      next if path.nil? || path.to_s.empty?
      puts "#{path}\t#{name}"
    end
  ' "$YAML" "$PLATFORM"
}

read_extra_urls() {
  ruby -ryaml -e '
    data = YAML.load_file(ARGV[0])
    platform = ARGV[1]
    extras = data.dig("release_assets", platform, "extra_urls") || []
    extras.each do |entry|
      if entry.is_a?(Hash)
        url = entry["url"]
        name = entry["name"] || File.basename(url.to_s)
      else
        url = entry
        name = File.basename(url.to_s)
      end
      next if url.nil? || url.to_s.empty?
      puts "#{url}\t#{name}"
    end
  ' "$YAML" "$PLATFORM"
}

read_local_extra_paths() {
  ruby -ryaml -e '
    data = YAML.load_file(ARGV[0])
    platform = ARGV[1]
    extras = data.dig("release_assets", platform, "local_extra_paths") || []
    extras.each do |entry|
      if entry.is_a?(Hash)
        path = entry["path"]
        name = entry["name"] || File.basename(path.to_s)
      else
        path = entry
        name = File.basename(path.to_s)
      end
      next if path.nil? || path.to_s.empty?
      puts "#{path}\t#{name}"
    end
  ' "$YAML" "$PLATFORM"
}

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
  *.7z)
    if command -v 7z >/dev/null 2>&1; then
      7z x -y "-o$tmp_dir" "$archive_path" >/dev/null
    elif command -v bsdtar >/dev/null 2>&1; then
      bsdtar -xf "$archive_path" -C "$tmp_dir"
    else
      echo "No extractor found for $archive_name; install 7z or bsdtar" >&2
      exit 1
    fi
    ;;
  *.exe) direct_asset=1 ;;
  *.jar) direct_asset=1 ;;
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

while IFS=$'\t' read -r extra_path extra_name; do
  [[ -n "$extra_path" ]] || continue
  extra_src="$tmp_dir/$extra_path"
  [[ -f "$extra_src" ]] || { echo "Missing extra asset path $extra_path for $ENGINE/$PLATFORM" >&2; exit 1; }
  cp "$extra_src" "$OUT/$extra_name"
done < <(read_extra_paths)

while IFS=$'\t' read -r extra_url extra_name; do
  [[ -n "$extra_url" ]] || continue
  curl -fsSL "$extra_url" -o "$OUT/$extra_name"
done < <(read_extra_urls)

while IFS=$'\t' read -r extra_path extra_name; do
  [[ -n "$extra_path" ]] || continue
  local_src="$ROOT/$extra_path"
  [[ -f "$local_src" ]] || { echo "Missing local extra path $extra_path for $ENGINE/$PLATFORM" >&2; exit 1; }
  cp "$local_src" "$OUT/$extra_name"
done < <(read_local_extra_paths)

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
