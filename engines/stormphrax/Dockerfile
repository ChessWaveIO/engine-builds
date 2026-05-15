FROM alpine:3.20 AS fetch

ARG ASSET_URL=https://github.com/Ciekce/Stormphrax/releases/download/v7.0.0/stormphrax-7.0.0-avx2
ARG ASSET_SHA256=a4f52602186f60cdf45789acf6eeb2b43ba2280a89524a43ee8ced4dff4a35b3
ARG BINARY_NAME=stormphrax-7.0.0-avx2
ARG LICENSE_URL=https://raw.githubusercontent.com/Ciekce/Stormphrax/main/LICENSE
ARG SOURCE_REF=v7.0.0

RUN apk add --no-cache curl
RUN set -eux; \
    mkdir -p /out /tmp/asset; \
    curl -fsSL "$ASSET_URL" -o /tmp/asset/download; \
    echo "$ASSET_SHA256  /tmp/asset/download" | sha256sum -c -; \
    cp /tmp/asset/download "/out/$BINARY_NAME"; \
    chmod 0755 "/out/$BINARY_NAME"; \
    curl -fsSL "$LICENSE_URL" -o /out/LICENSE || true; \
    printf 'Engine: stormphrax\nPlatform: linux-x86_64\nSource ref: %s\nAsset: %s\nAsset SHA256: %s\n' "$SOURCE_REF" "$ASSET_URL" "$ASSET_SHA256" > /out/UPSTREAM.txt

FROM scratch AS export
COPY --from=fetch /out/ /
