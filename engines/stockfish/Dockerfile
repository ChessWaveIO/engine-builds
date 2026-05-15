FROM alpine:3.20 AS fetch

ARG STOCKFISH_REPO=official-stockfish/Stockfish
ARG STOCKFISH_16_TAG=sf_16.1
ARG STOCKFISH_17_TAG=sf_17
ARG STOCKFISH_18_TAG=sf_18
ARG STOCKFISH_ONLY=
ARG STOCKFISH_ASSET_PATTERN=(ubuntu|linux).*(x86-64|x86_64).*(avx2|modern|sse41|bmi2)?
ARG STOCKFISH_SUFFIX=linux-x86_64

RUN apk add --no-cache curl python3 tar unzip xz
RUN set -eux; \
    mkdir -p /out; \
    for spec in \
      "16:${STOCKFISH_16_TAG}" \
      "17:${STOCKFISH_17_TAG}" \
      "18:${STOCKFISH_18_TAG}"; do \
      label="${spec%%:*}"; \
      tag="${spec#*:}"; \
      if [ -n "$STOCKFISH_ONLY" ] && [ "$label" != "$STOCKFISH_ONLY" ]; then continue; fi; \
      if [ -n "$STOCKFISH_ONLY" ]; then version_dir="/out"; else version_dir="/out/stockfish-$label"; fi; \
      tmp_dir="$(mktemp -d)"; \
      mkdir -p "$version_dir"; \
      api_url="https://api.github.com/repos/${STOCKFISH_REPO}/releases/tags/$tag"; \
      api_json="$(curl -fsSL "$api_url")"; \
      asset_url="$(printf '%s' "$api_json" | STOCKFISH_ASSET_PATTERN="$STOCKFISH_ASSET_PATTERN" python3 -c 'import json, os, re, sys; data=json.load(sys.stdin); pattern=re.compile(os.environ["STOCKFISH_ASSET_PATTERN"], re.I); matches=[a for a in data.get("assets", []) if pattern.search(a.get("name", ""))]; print(matches[0]["browser_download_url"] if matches else ""); sys.exit(0 if matches else 1)')"; \
      archive_name="${asset_url##*/}"; \
      archive_path="$tmp_dir/$archive_name"; \
      curl -fL "$asset_url" -o "$archive_path"; \
      case "$archive_name" in \
        *.tar.gz|*.tgz) tar -xzf "$archive_path" -C "$tmp_dir" ;; \
        *.tar.xz) tar -xJf "$archive_path" -C "$tmp_dir" ;; \
        *.tar) tar -xf "$archive_path" -C "$tmp_dir" ;; \
        *.zip) unzip -q "$archive_path" -d "$tmp_dir" ;; \
        *) echo "Unknown Stockfish archive type: $archive_name" >&2; exit 1 ;; \
      esac; \
      bin="$(find "$tmp_dir" -type f -perm -111 -name 'stockfish*' | head -n1)"; \
      if [ -z "$bin" ]; then echo "No Stockfish binary found in $archive_name" >&2; find "$tmp_dir" -maxdepth 3 -type f >&2; exit 1; fi; \
      out_name="stockfish-$label-$STOCKFISH_SUFFIX"; \
      cp "$bin" "$version_dir/$out_name"; \
      chmod 0755 "$version_dir/$out_name"; \
      printf 'Downloaded from: %s\nRepository: https://github.com/%s\nRelease tag: %s\nVersion label: %s\nPlatform suffix: %s\n' "$asset_url" "$STOCKFISH_REPO" "$tag" "$label" "$STOCKFISH_SUFFIX" > "$version_dir/STOCKFISH_UPSTREAM.txt"; \
      rm -rf "$tmp_dir"; \
    done

FROM scratch AS export
COPY --from=fetch /out/ /out/
