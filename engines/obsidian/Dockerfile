# syntax=docker/dockerfile:1.6
#
# Source build for Obsidian (C++, GPL-3.0). Self-contained Linux x86_64 binary
# with the NNUE embedded at compile time (-DEvalFile + incbin). Uses the `nopgo`
# target — the default PGO `make` target has a Windows-only powershell cleanup
# step that fails on Linux. Built for AVX2.

############################
# Builder
############################
FROM --platform=linux/amd64 ubuntu:24.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make gcc g++ file \
 && rm -rf /var/lib/apt/lists/*

ARG OBSIDIAN_REPO=https://github.com/gab8192/Obsidian
ARG OBSIDIAN_REF=v16.0
ARG OBSIDIAN_BUILD=avx2

WORKDIR /src
RUN git clone "${OBSIDIAN_REPO}" Obsidian \
 && cd Obsidian \
 && git fetch --all --tags --prune \
 && git checkout --force "${OBSIDIAN_REF}"

RUN git -C /src/Obsidian rev-parse HEAD > /src/OBSIDIAN_COMMIT.txt

# nopgo target downloads the default net (download-net) and embeds it.
RUN set -euo pipefail; \
    cd /src/Obsidian; \
    make nopgo build="${OBSIDIAN_BUILD}"; \
    test -x Obsidian; \
    file Obsidian; \
    strip Obsidian || true

############################
# Export stage
############################
FROM scratch AS export
COPY --from=builder /src/Obsidian/Obsidian   /obsidian-linux-x86_64
COPY --from=builder /src/OBSIDIAN_COMMIT.txt /OBSIDIAN_COMMIT.txt
