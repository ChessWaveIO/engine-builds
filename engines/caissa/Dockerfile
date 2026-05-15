# syntax=docker/dockerfile:1.6

############################
# Builder
############################
FROM --platform=linux/amd64 ubuntu:24.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git cmake make gcc g++ file \
 && rm -rf /var/lib/apt/lists/*

# ---- Build arguments ----
ARG CAISSA_REPO=https://github.com/Witek902/Caissa
ARG CAISSA_REF=master
ARG CAISSA_BIN_NAME=caissa

# Clone source
WORKDIR /src
RUN --mount=type=cache,target=/root/.cache/git \
    git clone "${CAISSA_REPO}" Caissa \
 && cd Caissa \
 && git fetch --all --tags --prune \
 && git checkout --force "${CAISSA_REF}"

# Record commit for provenance
WORKDIR /src/Caissa
RUN git rev-parse HEAD > /src/CAISSA_COMMIT.txt

# Build
RUN set -euo pipefail; \
    find . -name CMakeLists.txt -exec sed -i 's/INTERPROCEDURAL_OPTIMIZATION TRUE/INTERPROCEDURAL_OPTIMIZATION FALSE/g' {} +; \
    find . -name CMakeLists.txt -exec sed -i 's/ -Werror//g' {} +; \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=FALSE; \
    cmake --build build --parallel "$(nproc)" --target caissa; \
    test -x "/src/Caissa/build/bin/${CAISSA_BIN_NAME}"; \
    file "/src/Caissa/build/bin/${CAISSA_BIN_NAME}"; \
    strip "/src/Caissa/build/bin/${CAISSA_BIN_NAME}" || true

############################
# Export stage
############################
FROM scratch AS export
COPY --from=builder /src/Caissa/build/bin/caissa /caissa-linux-x86_64
COPY --from=builder /src/Caissa/data/neuralNets/eval-71.pnn /eval-71.pnn
COPY --from=builder /src/CAISSA_COMMIT.txt /CAISSA_COMMIT.txt

############################
# Deliver stage
############################
FROM alpine:3.20 AS deliver
COPY --from=export /caissa-linux-x86_64 /artifacts/
COPY --from=export /eval-71.pnn         /artifacts/
COPY --from=export /CAISSA_COMMIT.txt   /artifacts/
ENTRYPOINT ["/bin/sh","-c"]
CMD ["mkdir -p /dst \
 && install -m 0755 /artifacts/caissa-linux-x86_64 /dst/caissa-linux-x86_64 \
 && install -m 0644 /artifacts/eval-71.pnn         /dst/eval-71.pnn \
 && install -m 0644 /artifacts/CAISSA_COMMIT.txt   /dst/CAISSA_COMMIT.txt"]
