SHELL := /bin/bash

# Output dir and build pins
OUT ?= ../../out/v1.0.0/linux-x86_64/patricia
MAC_OUT ?= ../../out/v1.0.0/macos-silicon/patricia
PAT_REF ?= main
PAT_WINDOWS_RELEASE ?= v1.0.4
PAT_WINDOWS_ASSET ?= https://github.com/ChessWaveIO/test-engines/releases/download/$(PAT_WINDOWS_RELEASE)/patricia-windows-avx512.zip

.PHONY: prep linux linux-nocache macos-silicon windows clean

prep:
	@mkdir -p $(OUT)
	@chmod 0775 $(OUT)

linux: prep
	@set -e; \
	img=$$(docker build -q --target export -f Dockerfile \
		--build-arg PAT_REF=$(PAT_REF) \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/patricia-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/PATRICIA_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/patricia-linux-x86_64; \
	ls -l $(OUT)

linux-nocache: prep
	@set -e; \
	img=$$(docker build -q --no-cache --target export -f Dockerfile \
		--build-arg PAT_REF=$(PAT_REF) \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/patricia-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/PATRICIA_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/patricia-linux-x86_64; \
	ls -l $(OUT)

macos-silicon: prep
	@set -e; \
	if [ "$(OUT)" = "../../out/v1.0.0/linux-x86_64/patricia" ]; then OUT_DIR="$(MAC_OUT)"; else OUT_DIR="$(OUT)"; fi; \
	mkdir -p "$$OUT_DIR"; \
	chmod 0775 "$$OUT_DIR"; \
	iid=$$(mktemp); \
	docker build --target export -f Dockerfile.macos-silicon \
		--build-arg PAT_REF=$(PAT_REF) \
		--iidfile "$$iid" .; \
	img=$$(cat "$$iid"); rm -f "$$iid"; \
	cid=$$(docker create "$$img" /bin/true); \
	docker cp $$cid:/patricia-macos-arm64 "$$OUT_DIR"/; \
	docker cp $$cid:/PATRICIA_COMMIT.txt "$$OUT_DIR"/ || true; \
	docker rm $$cid; \
	cp -f "$$OUT_DIR"/patricia-macos-arm64 "$$OUT_DIR"/patricia; \
	rm -f "$$OUT_DIR"/patricia-macos-arm64; \
	chmod 0755 "$$OUT_DIR"/patricia; \
	ls -l "$$OUT_DIR"

windows: prep
	@set -euo pipefail; \
	tmp_dir="$$(mktemp -d)"; \
	archive="$$tmp_dir/patricia-windows-avx512.zip"; \
	curl -fsSL "$(PAT_WINDOWS_ASSET)" -o "$$archive"; \
	unzip -q "$$archive" -d "$$tmp_dir"; \
	cp "$$tmp_dir"/patricia*_avx512.exe "$(OUT)/patricia-windows-avx512.exe" 2>/dev/null || cp "$$tmp_dir"/patricia*avx512.exe "$(OUT)/patricia-windows-avx512.exe"; \
	cp "$$tmp_dir"/LICENSE "$(OUT)/PATRICIA_WINDOWS_LICENSE"; \
	printf 'Downloaded from: %s\nRelease tag: %s\n' "$(PAT_WINDOWS_ASSET)" "$(PAT_WINDOWS_RELEASE)" > "$(OUT)/PATRICIA_WINDOWS_UPSTREAM.txt"; \
	chmod 0755 "$(OUT)/patricia-windows-avx512.exe"; \
	rm -rf "$$tmp_dir"; \
	ls -l "$(OUT)"
clean:
	@rm -rf $(OUT)
