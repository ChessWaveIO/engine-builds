FROM alpine:3.20 AS fetch

ARG ASSET_URL=https://github.com/dede1751/carp/releases/download/v3.0.1/carp-v3.0.1-linux-x86_64-V1
ARG BINARY_NAME=carp-v3.0.1-linux-x86_64-V1
ARG LICENSE_URL=https://raw.githubusercontent.com/dede1751/carp/main/LICENSE
ARG SOURCE_REF=v3.0.1

RUN apk add --no-cache curl
RUN set -eux; \
    mkdir -p /out /tmp/asset; \
    curl -fsSL "$ASSET_URL" -o /tmp/asset/download; \
    cp /tmp/asset/download "/out/$BINARY_NAME"; \
    chmod 0755 "/out/$BINARY_NAME"; \
    curl -fsSL "$LICENSE_URL" -o /out/LICENSE || true; \
    printf 'Engine: carp\nPlatform: linux-x86_64\nSource ref: %s\nAsset: %s\n' "$SOURCE_REF" "$ASSET_URL" > /out/UPSTREAM.txt

FROM scratch AS export
COPY --from=fetch /out/ /
