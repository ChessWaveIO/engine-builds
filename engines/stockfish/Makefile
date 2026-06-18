SHELL := /bin/bash

OUT ?= ../../out/v1.0.0/macos-silicon/stockfish
STOCKFISH_REPO ?= official-stockfish/Stockfish
STOCKFISH_16_TAG ?= sf_16.1
STOCKFISH_17_TAG ?= sf_17
STOCKFISH_18_TAG ?= sf_18
STOCKFISH_ASSET_PATTERN ?= macos.*(m1|apple-silicon|arm64|aarch64)
STOCKFISH_SUFFIX ?= macos-arm64
STOCKFISH_EXE ?=
STOCKFISH_ONLY ?=

.PHONY: prep linux linux-nocache macos-silicon windows clean download

prep:
	@mkdir -p $(OUT)
	@chmod 0775 $(OUT)

linux: STOCKFISH_ASSET_PATTERN = ubuntu.*x86-64.*avx2
linux: STOCKFISH_SUFFIX = linux-x86_64
linux: prep download

linux-nocache: linux

macos-silicon: STOCKFISH_ASSET_PATTERN = macos.*(m1|apple-silicon|arm64|aarch64)
macos-silicon: STOCKFISH_SUFFIX = macos-arm64
macos-silicon: prep download

windows: STOCKFISH_ASSET_PATTERN = windows.*x86-64.*(avx2|modern|sse41|bmi2)?
windows: STOCKFISH_SUFFIX = windows-x86_64
windows: STOCKFISH_EXE = .exe
windows: prep download

download:
	@set -euo pipefail; \
	for spec in \
		"16:$(STOCKFISH_16_TAG)" \
		"17:$(STOCKFISH_17_TAG)" \
		"18:$(STOCKFISH_18_TAG)"; do \
		label="$${spec%%:*}"; \
		tag="$${spec#*:}"; \
		if [ -n "$(STOCKFISH_ONLY)" ] && [ "$$label" != "$(STOCKFISH_ONLY)" ]; then continue; fi; \
		if [ -n "$(STOCKFISH_ONLY)" ]; then version_dir="$(OUT)"; else version_dir="$(OUT)/stockfish-$$label"; fi; \
		tmp_dir="$$(mktemp -d)"; \
		mkdir -p "$$version_dir"; \
		api_url="https://api.github.com/repos/$(STOCKFISH_REPO)/releases/tags/$$tag"; \
		if [ -n "$${GITHUB_TOKEN:-}" ]; then \
			api_json="$$(curl -fsSL -H "Authorization: Bearer $${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "$$api_url")"; \
		else \
			api_json="$$(curl -fsSL "$$api_url")"; \
		fi; \
		asset_url="$$(printf '%s' "$$api_json" | STOCKFISH_ASSET_PATTERN='$(STOCKFISH_ASSET_PATTERN)' python3 -c 'import json, os, re, sys; data=json.load(sys.stdin); pattern=re.compile(os.environ["STOCKFISH_ASSET_PATTERN"], re.I); assets=data.get("assets", []); matches=[a for a in assets if pattern.search(a.get("name", ""))]; print(matches[0]["browser_download_url"] if matches else ""); sys.exit(0 if matches else 1)')"; \
		archive_name="$${asset_url##*/}"; \
		archive_path="$$tmp_dir/$$archive_name"; \
		curl -fL "$$asset_url" -o "$$archive_path"; \
		case "$$archive_name" in \
			*.tar.gz|*.tgz) tar -xzf "$$archive_path" -C "$$tmp_dir" ;; \
			*.tar.xz) tar -xJf "$$archive_path" -C "$$tmp_dir" ;; \
			*.tar) tar -xf "$$archive_path" -C "$$tmp_dir" ;; \
			*.zip) unzip -q "$$archive_path" -d "$$tmp_dir" ;; \
			*) echo "Unknown Stockfish archive type: $$archive_name" >&2; exit 1 ;; \
		esac; \
		if [ -n "$(STOCKFISH_EXE)" ]; then \
			bin="$$(find "$$tmp_dir" -type f -iname 'stockfish*.exe' | head -n1)"; \
		else \
			bin="$$(find "$$tmp_dir" -type f -perm -111 -name 'stockfish*' | head -n1)"; \
		fi; \
		if [ -z "$$bin" ]; then echo "No Stockfish binary found in $$archive_name" >&2; find "$$tmp_dir" -maxdepth 3 -type f >&2; exit 1; fi; \
		out_name="stockfish-$$label-$(STOCKFISH_SUFFIX)$(STOCKFISH_EXE)"; \
		cp "$$bin" "$$version_dir/$$out_name"; \
		chmod 0755 "$$version_dir/$$out_name"; \
		printf 'Downloaded from: %s\nRepository: https://github.com/%s\nRelease tag: %s\nVersion label: %s\nPlatform suffix: %s\n' "$$asset_url" "$(STOCKFISH_REPO)" "$$tag" "$$label" "$(STOCKFISH_SUFFIX)" > "$$version_dir/STOCKFISH_UPSTREAM.txt"; \
		rm -rf "$$tmp_dir"; \
	done; \
	ls -l $(OUT)

clean:
	@rm -rf $(OUT)
