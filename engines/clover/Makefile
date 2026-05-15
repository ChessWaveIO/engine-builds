SHELL := /bin/bash

# Output dir and build pins
OUT ?= ../../out/v1.0.0/linux-x86_64/clover
MAC_OUT ?= ../../out/v1.0.0/macos-silicon/clover
CLOVER_REF ?= master
CLOVER_VARIANT ?= auto   # auto|old|avx2|avx512 (Dockerfile supports this)

.PHONY: prep linux linux-nocache macos-silicon clean

prep:
	@mkdir -p $(OUT)
	@chmod 0775 $(OUT)

linux: prep
	@set -e; \
	img=$$(docker build -q --target export -f Dockerfile \
		--build-arg CLOVER_REF=$(CLOVER_REF) \
		--build-arg CLOVER_VARIANT=$(CLOVER_VARIANT) \
		. | tail -n1); \
	[ -n "$$img" ] || { echo "docker build did not return an image id"; exit 1; }; \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/clover-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/CLOVER_COMMIT.txt   $(OUT)/; \
	docker cp $$cid:/CLOVER_MANIFEST.txt $(OUT)/; \
	docker cp $$cid:/quantised.nnue      $(OUT)/ || true; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/clover-linux-x86_64; \
	ls -l $(OUT); echo "-----"; \
	[ -f $(OUT)/CLOVER_MANIFEST.txt ] && cat $(OUT)/CLOVER_MANIFEST.txt || true

linux-nocache: prep
	@set -e; \
	img=$$(docker build -q --no-cache --target export -f Dockerfile \
		--build-arg CLOVER_REF=$(CLOVER_REF) \
		--build-arg CLOVER_VARIANT=$(CLOVER_VARIANT) \
		. | tail -n1); \
	[ -n "$$img" ] || { echo "docker build did not return an image id"; exit 1; }; \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/clover-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/CLOVER_COMMIT.txt   $(OUT)/; \
	docker cp $$cid:/CLOVER_MANIFEST.txt $(OUT)/; \
	docker cp $$cid:/quantised.nnue      $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/clover-linux-x86_64; \
	ls -l $(OUT); echo "-----"; \
	[ -f $(OUT)/CLOVER_MANIFEST.txt ] && cat $(OUT)/CLOVER_MANIFEST.txt || true

macos-silicon: prep
	@set -e; \
	if [ "$(OUT)" = "../../out/v1.0.0/linux-x86_64/clover" ]; then OUT_DIR="$(MAC_OUT)"; else OUT_DIR="$(OUT)"; fi; \
	mkdir -p "$$OUT_DIR"; \
	chmod 0775 "$$OUT_DIR"; \
	iid=$$(mktemp); \
	docker build --target export -f Dockerfile.macos-silicon --iidfile "$$iid" .; \
	img=$$(cat "$$iid"); rm -f "$$iid"; \
	cid=$$(docker create "$$img" /bin/true); \
	docker cp $$cid:/clover-macos-arm64 "$$OUT_DIR"/; \
	docker cp $$cid:/CLOVER_COMMIT.txt "$$OUT_DIR"/ || true; \
	docker cp $$cid:/quantised.nnue "$$OUT_DIR"/ || true; \
	docker rm $$cid; \
	cp -f "$$OUT_DIR"/clover-macos-arm64 "$$OUT_DIR"/clover; \
	rm -f "$$OUT_DIR"/clover-macos-arm64; \
	chmod 0755 "$$OUT_DIR"/clover; \
	ls -l "$$OUT_DIR"
clean:
	@rm -rf $(OUT)
