# syntax=docker/dockerfile:1.6

############################
# Builder
############################
FROM --platform=linux/amd64 ubuntu:22.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Minimal deps: clang toolchain + build utils
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make clang file \
 && rm -rf /var/lib/apt/lists/*

# ---- Reproducible pins (override at build time) ----
ARG ETH_REPO=https://github.com/AndyGrant/Ethereal
ARG ETH_REF=master              # tag/branch/SHA
ARG ETH_BIN_NAME=Ethereal       # final binary name
# Optional: embed license owner, or build NNUE by supplying EVALFILE (path)
ARG ETH_OWNER=                  # e.g. "ChessWave"
ARG ETH_EVALFILE_URL=           # e.g. https://example.com/network.nnue

# Fetch source
WORKDIR /src
RUN --mount=type=cache,target=/root/.cache/git \
    git clone "${ETH_REPO}" . \
 && git fetch --all --tags --prune \
 && git checkout --force "${ETH_REF}"

# Record exact commit for provenance
RUN git rev-parse HEAD > /src/ETHEREAL_COMMIT.txt

# Optionally fetch an NNUE network and point the Makefile at it
# If ETH_EVALFILE_URL is set, we download to /src/nnue/net.nnue
RUN if [[ -n "${ETH_EVALFILE_URL}" ]]; then \
      mkdir -p /src/nnue && \
      curl -L "${ETH_EVALFILE_URL}" -o /src/nnue/net.nnue && \
      echo "NNUE downloaded: /src/nnue/net.nnue"; \
    fi

# Build (native-tuned "basic" target; static-free for broad glibc compatibility)
# - Classic eval: no EVALFILE/OWNER passed
# - NNUE eval: pass EVALFILE=/src/nnue/net.nnue
# - OWNER: optional string embedded via -DLICENSE_OWNER
WORKDIR /src/src
RUN set -euo pipefail; \
    EXTRA_VARS="EXE=${ETH_BIN_NAME}"; \
    if [[ -n "${ETH_OWNER}" ]]; then EXTRA_VARS="${EXTRA_VARS} OWNER=${ETH_OWNER}"; fi; \
    if [[ -n "${ETH_EVALFILE_URL}" ]]; then EXTRA_VARS="${EXTRA_VARS} EVALFILE=/src/nnue/net.nnue"; fi; \
    make -B -j"$(nproc)" basic CC=clang ${EXTRA_VARS} ; \
    test -x "./${ETH_BIN_NAME}" ; \
    file "./${ETH_BIN_NAME}" ; \
    strip "./${ETH_BIN_NAME}" || true

############################
# Export stage (artifacts)
############################
FROM scratch AS export
COPY --from=builder /src/src/${ETH_BIN_NAME}     /ethereal-linux-x86_64
COPY --from=builder /src/ETHEREAL_COMMIT.txt     /ETHEREAL_COMMIT.txt

############################
# Deliver stage (copy to /dst with perms)
############################
FROM --platform=linux/amd64 alpine:3.20 AS deliver
COPY --from=export /ethereal-linux-x86_64 /artifacts/
COPY --from=export /ETHEREAL_COMMIT.txt   /artifacts/
ENTRYPOINT ["/bin/sh","-c"]
CMD ["mkdir -p /dst \
 && install -m 0755 /artifacts/ethereal-linux-x86_64 /dst/ethereal-linux-x86_64 \
 && install -m 0644 /artifacts/ETHEREAL_COMMIT.txt   /dst/ETHEREAL_COMMIT.txt"]
