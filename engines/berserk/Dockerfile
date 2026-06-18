# syntax=docker/dockerfile:1.6
#
# Source build for Berserk (C, GPL-3.0). Produces a self-contained Linux
# x86_64 binary with the default NNUE embedded at compile time (-DEVALFILE),
# so no external network file is needed at runtime.
#
# Built portably for AVX2 (Haswell/Excavator+), the de-facto baseline for
# distributed chess engines.

############################
# Builder
############################
FROM --platform=linux/amd64 ubuntu:24.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git make clang lld llvm gcc g++ file \
 && rm -rf /var/lib/apt/lists/*

ARG BERSERK_REPO=https://github.com/jhonnold/berserk
ARG BERSERK_REF=13
ARG BERSERK_ARCH=avx2
# Net for ref 13 — fetched from the main repo's tag release because the
# makefile's berserk-networks URL 404s for this version. `make build` reuses an
# already-present EVALFILE instead of re-downloading.
ARG BERSERK_NET=berserk-d43206fe90e4.nn

WORKDIR /src
RUN git clone "${BERSERK_REPO}" berserk \
 && cd berserk \
 && git fetch --all --tags --prune \
 && git checkout --force "${BERSERK_REF}"

RUN git -C /src/berserk rev-parse HEAD > /src/BERSERK_COMMIT.txt

# Pre-place the verified network so the build embeds it (avoids the broken
# makefile download), then compile (clang + LTO) with the net baked in.
RUN set -euo pipefail; \
    cd /src/berserk/src; \
    curl -fSL -o "${BERSERK_NET}" \
      "https://github.com/jhonnold/berserk/releases/download/${BERSERK_REF}/${BERSERK_NET}"; \
    make ARCH="${BERSERK_ARCH}" build; \
    test -x berserk; \
    file berserk; \
    strip berserk || true

############################
# Export stage (Makefile.release-import copies /<binary> from here)
############################
FROM scratch AS export
COPY --from=builder /src/berserk/src/berserk /berserk-linux-x86_64
COPY --from=builder /src/BERSERK_COMMIT.txt  /BERSERK_COMMIT.txt
