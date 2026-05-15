FROM alpine:3.20 AS fetch

ARG ASSET_URL=https://github.com/zzzzz151/Starzix/releases/download/6.1/starzix-6.1-avx2
ARG BINARY_NAME=starzix-6.1-avx2
ARG LICENSE_URL=https://raw.githubusercontent.com/zzzzz151/Starzix/main/LICENSE
ARG SOURCE_REF=6.1

RUN apk add --no-cache curl
RUN set -eux; \
    mkdir -p /out /tmp/asset; \
    curl -fsSL "$ASSET_URL" -o /tmp/asset/download; \
    cp /tmp/asset/download "/out/$BINARY_NAME"; \
    chmod 0755 "/out/$BINARY_NAME"; \
    curl -fsSL "$LICENSE_URL" -o /out/LICENSE || true; \
    printf 'Engine: starzix\nPlatform: linux-x86_64\nSource ref: %s\nAsset: %s\n' "$SOURCE_REF" "$ASSET_URL" > /out/UPSTREAM.txt

FROM scratch AS export
COPY --from=fetch /out/ /
