# syntax=docker/dockerfile:1.6

############################
# Builder
############################
FROM --platform=linux/amd64 ubuntu:22.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Minimal build deps for Patricia (Make + GCC toolchain)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make gcc g++ file \
 && rm -rf /var/lib/apt/lists/*

# ---- Reproducible pins (override at build time) ----
ARG PAT_REPO=https://github.com/Adam-Kulju/Patricia
ARG PAT_REF=main               # tag/branch/SHA
ARG PAT_BIN_NAME=patricia      # produced by 'make -B' in ./engine

# Fetch source
WORKDIR /src
RUN --mount=type=cache,target=/root/.cache/git \
    git clone "${PAT_REPO}" . \
 && git fetch --all --tags --prune \
 && git checkout --force "${PAT_REF}"

# Record exact commit for provenance
RUN git rev-parse HEAD > /src/PATRICIA_COMMIT.txt

# Build (per upstream instructions)
WORKDIR /src/engine
RUN set -euo pipefail; \
    make -B -j"$(nproc)" CXX=g++ CC=gcc; \
    test -x "./${PAT_BIN_NAME}"; \
    file "./${PAT_BIN_NAME}"; \
    strip "./${PAT_BIN_NAME}" || true

############################
# Export stage (artifacts)
############################
FROM scratch AS export
# Put artifacts at image root so -o type=local,dest=... writes them directly
COPY --from=builder /src/engine/${PAT_BIN_NAME} /patricia-linux-x86_64
COPY --from=builder /src/PATRICIA_COMMIT.txt     /PATRICIA_COMMIT.txt

############################
# Deliver stage (copy to /dst with perms)
############################
FROM --platform=linux/amd64 alpine:3.20 AS deliver
COPY --from=export /patricia-linux-x86_64 /artifacts/
COPY --from=export /PATRICIA_COMMIT.txt   /artifacts/
ENTRYPOINT ["/bin/sh","-c"]
CMD ["mkdir -p /dst \
 && install -m 0755 /artifacts/patricia-linux-x86_64 /dst/patricia-linux-x86_64 \
 && install -m 0644 /artifacts/PATRICIA_COMMIT.txt   /dst/PATRICIA_COMMIT.txt"]
