SHELL := /bin/bash

OUT ?= ../../out/v1.0.0/linux-x86_64/caissa
MAC_OUT ?= ../../out/v1.0.0/macos-silicon/caissa
CAISSA_REF ?= master
CAISSA_WINDOWS_RELEASE ?= v1.0.4
CAISSA_WINDOWS_ASSET ?= https://github.com/ChessWaveIO/test-engines/releases/download/$(CAISSA_WINDOWS_RELEASE)/caissa-windows-avx512.zip

.PHONY: prep linux linux-nocache macos-silicon macos-silicon-bench windows clean

prep:
	@mkdir -p $(OUT)
	@chmod 0775 $(OUT)

linux: prep
	@set -e; \
	img=$$(docker build -q --target export -f Dockerfile \
		--build-arg CAISSA_REF=$(CAISSA_REF) \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/caissa-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/eval-71.pnn $(OUT)/; \
	docker cp $$cid:/CAISSA_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/caissa-linux-x86_64; \
	ls -l $(OUT)

linux-nocache: prep
	@set -e; \
	img=$$(docker build -q --no-cache --target export -f Dockerfile \
		--build-arg CAISSA_REF=$(CAISSA_REF) \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/caissa-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/eval-71.pnn $(OUT)/; \
	docker cp $$cid:/CAISSA_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/caissa-linux-x86_64; \
	ls -l $(OUT)

macos-silicon: prep
	@set -e; \
	if [ "$(OUT)" = "../../out/v1.0.0/linux-x86_64/caissa" ]; then OUT_DIR="$(MAC_OUT)"; else OUT_DIR="$(OUT)"; fi; \
	mkdir -p "$$OUT_DIR"; \
	chmod 0775 "$$OUT_DIR"; \
	iid=$$(mktemp); \
	docker build --target export -f Dockerfile.macos-silicon --iidfile "$$iid" .; \
	img=$$(cat "$$iid"); rm -f "$$iid"; \
	cid=$$(docker create "$$img" /bin/true); \
	docker cp $$cid:/caissa-macos-arm64 "$$OUT_DIR"/; \
	docker cp $$cid:/eval-71.pnn "$$OUT_DIR"/ || true; \
	docker cp $$cid:/CAISSA_COMMIT.txt "$$OUT_DIR"/ || true; \
	docker rm $$cid; \
	cp -f "$$OUT_DIR"/caissa-macos-arm64 "$$OUT_DIR"/caissa; \
	rm -f "$$OUT_DIR"/caissa-macos-arm64; \
	chmod 0755 "$$OUT_DIR"/caissa; \
	ls -l "$$OUT_DIR"

macos-silicon-bench: macos-silicon
	@set -e; \
	if [ "$(OUT)" = "../../out/v1.0.0/linux-x86_64/caissa" ]; then OUT_DIR="$(MAC_OUT)"; else OUT_DIR="$(OUT)"; fi; \
	cd "$$OUT_DIR"; \
	./caissa bench

windows: prep
	@set -euo pipefail; \
	tmp_dir="$$(mktemp -d)"; \
	archive="$$tmp_dir/caissa-windows-avx512.zip"; \
	curl -fsSL "$(CAISSA_WINDOWS_ASSET)" -o "$$archive"; \
	unzip -q "$$archive" -d "$$tmp_dir"; \
	cp "$$tmp_dir"/caissa-*-x64-avx512.exe "$(OUT)/caissa-windows-avx512.exe"; \
	cp "$$tmp_dir"/eval-*.pnn "$(OUT)/"; \
	cp "$$tmp_dir"/LICENSE "$(OUT)/CAISSA_WINDOWS_LICENSE"; \
	printf 'Downloaded from: %s\nRelease tag: %s\n' "$(CAISSA_WINDOWS_ASSET)" "$(CAISSA_WINDOWS_RELEASE)" > "$(OUT)/CAISSA_WINDOWS_UPSTREAM.txt"; \
	chmod 0755 "$(OUT)/caissa-windows-avx512.exe"; \
	rm -rf "$$tmp_dir"; \
	ls -l "$(OUT)"
clean:
	@rm -rf $(OUT)
