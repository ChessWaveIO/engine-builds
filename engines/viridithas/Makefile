SHELL := /bin/bash

OUT ?= ../../out/v1.0.0/linux-x86_64/viridithas
MAC_OUT ?= ../../out/v1.0.0/macos-silicon/viridithas
VIRI_REF ?= master
NET_TAG ?= latest
GITHUB_TOKEN ?=

.PHONY: prep linux linux-nocache macos-silicon clean

prep:
	@mkdir -p $(OUT)
	@chmod 0775 $(OUT)

linux: prep
	@set -e; \
	img=$$(docker build -q --target export -f Dockerfile \
		--build-arg VIRI_REF=$(VIRI_REF) \
		--build-arg NET_TAG=$(NET_TAG) \
		--build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/viridithas-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/viridithas.nnue.zst     $(OUT)/; \
	docker cp $$cid:/VIRIDITHAS_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/viridithas-linux-x86_64; \
	ls -l $(OUT)

linux-nocache: prep
	@set -e; \
	img=$$(docker build -q --no-cache --target export -f Dockerfile \
		--build-arg VIRI_REF=$(VIRI_REF) \
		--build-arg NET_TAG=$(NET_TAG) \
		--build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/viridithas-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/viridithas.nnue.zst     $(OUT)/; \
	docker cp $$cid:/VIRIDITHAS_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/viridithas-linux-x86_64; \
	ls -l $(OUT)

macos-silicon: prep
	@set -e; \
	if [ "$(OUT)" = "../../out/v1.0.0/linux-x86_64/viridithas" ]; then OUT_DIR="$(MAC_OUT)"; else OUT_DIR="$(OUT)"; fi; \
	mkdir -p "$$OUT_DIR"; \
	chmod 0775 "$$OUT_DIR"; \
	iid=$$(mktemp); \
	docker build --target export -f Dockerfile.macos-silicon \
		--build-arg VIRI_REF=$(VIRI_REF) \
		--build-arg NET_TAG=$(NET_TAG) \
		--build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) \
		--iidfile "$$iid" .; \
	img=$$(cat "$$iid"); rm -f "$$iid"; \
	cid=$$(docker create "$$img" /bin/true); \
	docker cp $$cid:/viridithas-macos-arm64 "$$OUT_DIR"/; \
	docker cp $$cid:/viridithas.nnue.zst "$$OUT_DIR"/ || true; \
	docker cp $$cid:/VIRIDITHAS_COMMIT.txt "$$OUT_DIR"/ || true; \
	docker rm $$cid; \
	cp -f "$$OUT_DIR"/viridithas-macos-arm64 "$$OUT_DIR"/viridithas; \
	rm -f "$$OUT_DIR"/viridithas-macos-arm64; \
	chmod 0755 "$$OUT_DIR"/viridithas; \
	ls -l "$$OUT_DIR"
clean:
	@rm -rf $(OUT)
