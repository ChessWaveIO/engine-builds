FROM alpine:3.20 AS fetch

ARG ASSET_URL=https://github.com/Luecx/Koivisto/releases/download/v9.0/Koivisto_9.0-linux-avx2-pgo
ARG BINARY_NAME=Koivisto_9.0-linux-avx2-pgo
ARG LICENSE_URL=https://raw.githubusercontent.com/Luecx/Koivisto/master/LICENSE
ARG SOURCE_REF=v9.0

RUN apk add --no-cache curl
RUN set -eux; \
    mkdir -p /out /tmp/asset; \
    curl -fsSL "$ASSET_URL" -o /tmp/asset/download; \
    cp /tmp/asset/download "/out/$BINARY_NAME"; \
    chmod 0755 "/out/$BINARY_NAME"; \
    curl -fsSL "$LICENSE_URL" -o /out/LICENSE || true; \
    printf 'Engine: koivisto\nPlatform: linux-x86_64\nSource ref: %s\nAsset: %s\n' "$SOURCE_REF" "$ASSET_URL" > /out/UPSTREAM.txt

FROM scratch AS export
COPY --from=fetch /out/ /
