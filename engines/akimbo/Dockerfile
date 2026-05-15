FROM alpine:3.20 AS fetch

ARG ASSET_URL=https://github.com/jw1912/akimbo/releases/download/v1.0.0/akimbo-1.0.0
ARG BINARY_NAME=akimbo-1.0.0
ARG LICENSE_URL=https://raw.githubusercontent.com/jw1912/akimbo/main/LICENSE
ARG SOURCE_REF=v1.0.0

RUN apk add --no-cache curl
RUN set -eux; \
    mkdir -p /out /tmp/asset; \
    curl -fsSL "$ASSET_URL" -o /tmp/asset/download; \
    cp /tmp/asset/download "/out/$BINARY_NAME"; \
    chmod 0755 "/out/$BINARY_NAME"; \
    curl -fsSL "$LICENSE_URL" -o /out/LICENSE || true; \
    printf 'Engine: akimbo\nPlatform: linux-x86_64\nSource ref: %s\nAsset: %s\n' "$SOURCE_REF" "$ASSET_URL" > /out/UPSTREAM.txt

FROM scratch AS export
COPY --from=fetch /out/ /
