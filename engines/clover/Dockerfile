# syntax=docker/dockerfile:1.6

############################
# Builder
############################
FROM --platform=linux/amd64 ubuntu:22.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make gcc g++ file \
 && rm -rf /var/lib/apt/lists/*

# ---- Pins / knobs ----
ARG CLOVER_REPO=https://github.com/lucametehau/CloverEngine
ARG CLOVER_REF=master                  # tag/branch/SHA
# Pick which upstream variant to ship: auto|old|avx2|avx512
ARG CLOVER_VARIANT=auto

WORKDIR /src
RUN --mount=type=cache,target=/root/.cache/git \
    git clone "${CLOVER_REPO}" . \
 && git fetch --all --tags --prune \
 && git checkout --force "${CLOVER_REF}"

RUN git rev-parse HEAD > /src/CLOVER_COMMIT.txt

WORKDIR /src/src
RUN set -euo pipefail; \
    make -B release CC=gcc CXX=g++; \
    # Decide binary to export
    pick=""; \
    case "${CLOVER_VARIANT}" in \
      avx512) patts=("Clover*avx512*");; \
      avx2)   patts=("Clover*avx2*");; \
      old)    patts=("Clover*old*");; \
      *)      patts=("Clover*avx512*" "Clover*avx2*" "Clover*old*");; \
    esac; \
    for pat in "${patts[@]}"; do \
      cand=$(/usr/bin/env bash -lc 'shopt -s nullglob; for f in '"$pat"'; do echo "$f"; done' | head -n1 || true); \
      if [[ -n "${cand:-}" && -f "$cand" ]]; then pick="$cand"; break; fi; \
    done; \
    if [[ -z "${pick}" ]]; then pick=$(ls -1t Clover* 2>/dev/null | head -n1 || true); fi; \
    test -n "${pick}" && test -f "${pick}" || { echo "ERROR: No Clover binary found"; ls -l; exit 2; }; \
    cp -f "${pick}" /src/clover-linux-x86_64; \
    chmod 0755 /src/clover-linux-x86_64; \
    file /src/clover-linux-x86_64; \
    strip /src/clover-linux-x86_64 || true; \
    # Try to collect NNUE
    nnue_src=""; \
    for p in /src/src/quantised.nnue /src/quantised.nnue; do [[ -f "$p" ]] && nnue_src="$p" && break; done; \
    if [[ -z "${nnue_src}" ]]; then nnue_src=$(ls -1 /src/src/*.nnue /src/*.nnue 2>/dev/null | head -n1 || true); fi; \
    if [[ -n "${nnue_src}" && -f "${nnue_src}" ]]; then cp -f "${nnue_src}" /src/quantised.nnue; fi; \
    # Manifest
    { \
      echo "CLOVER_COMMIT=$(cat /src/CLOVER_COMMIT.txt)"; \
      echo "SELECTED=$(basename "$pick")"; \
      [[ -f /src/quantised.nnue ]] && echo "NNUE=quantised.nnue" || echo "NNUE=<none>"; \
    } > /src/CLOVER_MANIFEST.txt; \
    cat /src/CLOVER_MANIFEST.txt

############################
# Export
############################
FROM scratch AS export
COPY --from=builder /src/clover-linux-x86_64 /clover-linux-x86_64
COPY --from=builder /src/CLOVER_COMMIT.txt    /CLOVER_COMMIT.txt
COPY --from=builder /src/CLOVER_MANIFEST.txt  /CLOVER_MANIFEST.txt
COPY --from=builder /src/quantised.nnue       /quantised.nnue
