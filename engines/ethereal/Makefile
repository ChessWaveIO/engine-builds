SHELL := /bin/bash

# Output dir and build pins
OUT ?= ../../out/v1.0.0/linux-x86_64/ethereal
MAC_OUT ?= ../../out/v1.0.0/macos-silicon/ethereal
ETH_REF ?= master
# Optional knobs (empty by default)
OWNER ?=
EVALFILE_URL ?=

.PHONY: prep linux linux-nocache macos-silicon clean

prep:
	@mkdir -p $(OUT)
	@chmod 0775 $(OUT)

linux: prep
	@set -e; \
	img=$$(docker build --target export -q -f Dockerfile \
		--build-arg ETH_REF=$(ETH_REF) \
		--build-arg ETH_OWNER="$(OWNER)" \
		--build-arg ETH_EVALFILE_URL="$(EVALFILE_URL)" \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/ethereal-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/ETHEREAL_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/ethereal-linux-x86_64; \
	ls -l $(OUT)

linux-nocache: prep
	@set -e; \
	img=$$(docker build -q --no-cache --target export -f Dockerfile \
		--build-arg ETH_REF=$(ETH_REF) \
		--build-arg ETH_OWNER="$(OWNER)" \
		--build-arg ETH_EVALFILE_URL="$(EVALFILE_URL)" \
		.); \
	cid=$$(docker create $$img /bin/true); \
	docker cp $$cid:/ethereal-linux-x86_64 $(OUT)/; \
	docker cp $$cid:/ETHEREAL_COMMIT.txt   $(OUT)/; \
	docker rm $$cid; \
	chmod 0755 $(OUT)/ethereal-linux-x86_64; \
	ls -l $(OUT)

macos-silicon: prep
	@set -e; \
	if [ "$(OUT)" = "../../out/v1.0.0/linux-x86_64/ethereal" ]; then OUT_DIR="$(MAC_OUT)"; else OUT_DIR="$(OUT)"; fi; \
	mkdir -p "$$OUT_DIR"; \
	chmod 0775 "$$OUT_DIR"; \
	iid=$$(mktemp); \
	docker build --target export -f Dockerfile.macos-silicon --iidfile "$$iid" .; \
	img=$$(cat "$$iid"); rm -f "$$iid"; \
	cid=$$(docker create "$$img" /bin/true); \
	docker cp $$cid:/ethereal-macos-arm64 "$$OUT_DIR"/; \
	docker cp $$cid:/ETHEREAL_COMMIT.txt "$$OUT_DIR"/ || true; \
	docker rm $$cid; \
	cp -f "$$OUT_DIR"/ethereal-macos-arm64 "$$OUT_DIR"/ethereal; \
	rm -f "$$OUT_DIR"/ethereal-macos-arm64; \
	chmod 0755 "$$OUT_DIR"/ethereal; \
	ls -l "$$OUT_DIR"
clean:
	@rm -rf $(OUT)
