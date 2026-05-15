FROM alpine:3.20 AS fetch

ARG ASSET_URL=https://github.com/Matthies/RubiChess/releases/download/20240817/RubiChess-20240817.zip
ARG ASSET_SHA256=03f613173cdd34998d8a01e972d8348791d11369c1506e96cc33467a1666bf86
ARG ASSET_PATH=RubiChess-20240817/linux/RubiChess-20240817_x86-64
ARG BINARY_NAME=RubiChess-20240817_x86-64
ARG LICENSE_URL=https://raw.githubusercontent.com/Matthies/RubiChess/master/License.txt
ARG SOURCE_REF=20240817

RUN apk add --no-cache curl unzip
RUN set -eux; \
    mkdir -p /out /tmp/asset; \
    curl -fsSL "$ASSET_URL" -o /tmp/asset/download.zip; \
    echo "$ASSET_SHA256  /tmp/asset/download.zip" | sha256sum -c -; \
    unzip -q /tmp/asset/download.zip -d /tmp/asset; \
    cp "/tmp/asset/$ASSET_PATH" "/out/$BINARY_NAME"; \
    chmod 0755 "/out/$BINARY_NAME"; \
    curl -fsSL "$LICENSE_URL" -o /out/LICENSE || true; \
    printf 'Engine: rubichess\nPlatform: linux-x86_64\nSource ref: %s\nAsset: %s\nAsset SHA256: %s\n' "$SOURCE_REF" "$ASSET_URL" "$ASSET_SHA256" > /out/UPSTREAM.txt

FROM scratch AS export
COPY --from=fetch /out/ /
