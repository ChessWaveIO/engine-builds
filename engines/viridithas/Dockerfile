# syntax=docker/dockerfile:1.6

############################
# Builder (no host deps needed)
############################
FROM --platform=linux/amd64 ubuntu:22.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


# Minimal toolchain for Viridithas + bindgen + musl (static)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make gcc g++ clang llvm lld pkg-config \
    jq zstd musl-tools cmake \
 && rm -rf /var/lib/apt/lists/*

# Install Rust and musl target (local to container)
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add x86_64-unknown-linux-musl

# ---- Reproducible pins (override at build time) ----
ARG VIRI_REPO=https://github.com/cosmobobak/viridithas
ARG VIRI_REF=master      # tag/commit/SHA
ARG NET_OWNER=cosmobobak
ARG NET_REPO=viridithas-networks
ARG NET_TAG=latest       # tag or "latest"
ARG GITHUB_TOKEN         # optional, avoids API rate limits

# Fetch source
WORKDIR /src
RUN --mount=type=cache,target=/root/.cache/git \
    git clone "${VIRI_REPO}" . \
 && git fetch --all --tags --prune \
 && git checkout --force "${VIRI_REF}" \
 && git submodule update --init --recursive

# Download the latest (or pinned) NNUE .zst next to the binary
RUN set -eux; \
    api_base="https://api.github.com/repos/${NET_OWNER}/${NET_REPO}/releases"; \
    if [ "${NET_TAG}" = "latest" ]; then api_url="${api_base}/latest"; else api_url="${api_base}/tags/${NET_TAG}"; fi; \
    auth=(); [ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: token ${GITHUB_TOKEN}"); \
    curl -fsSL "${auth[@]}" "${api_url}" \
      | jq -r '.assets[].browser_download_url | select(endswith(".zst"))' \
      | head -n1 \
      | xargs -r -I{} curl -fSL -o viridithas.nnue.zst "{}"; \
    test -s viridithas.nnue.zst

# Build static Linux x86_64 binary (musl)
ENV CC_x86_64_unknown_linux_musl=musl-gcc \
    CXX_x86_64_unknown_linux_musl=musl-g++ \
    RUSTFLAGS="-C target-cpu=x86-64 -C link-arg=-s"

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    cargo build --release --target x86_64-unknown-linux-musl --features syzygy,bindgen

# Record exact commit for provenance
RUN git rev-parse HEAD > /src/VIRIDITHAS_COMMIT.txt

############################
# Export stage (for file output to host)
############################
FROM scratch AS export
# Put artifacts at the image root so `-o` gives them directly
COPY --from=builder /src/target/x86_64-unknown-linux-musl/release/viridithas /viridithas-linux-x86_64
COPY --from=builder /src/viridithas.nnue.zst                                   /viridithas.nnue.zst
COPY --from=builder /src/VIRIDITHAS_COMMIT.txt                                 /VIRIDITHAS_COMMIT.txt

# ---- Deliver stage: copy artifacts to a mounted /dst without preserving ownership
FROM --platform=linux/amd64 alpine:3.20 AS deliver
COPY --from=export /viridithas-linux-x86_64 /artifacts/
COPY --from=export /viridithas.nnue.zst     /artifacts/
COPY --from=export /VIRIDITHAS_COMMIT.txt   /artifacts/
ENTRYPOINT ["/bin/sh","-c"]
CMD ["mkdir -p /dst \
 && install -m 0755 /artifacts/viridithas-linux-x86_64 /dst/viridithas-linux-x86_64 \
 && install -m 0644 /artifacts/viridithas.nnue.zst     /dst/viridithas.nnue.zst \
 && install -m 0644 /artifacts/VIRIDITHAS_COMMIT.txt   /dst/VIRIDITHAS_COMMIT.txt"]
