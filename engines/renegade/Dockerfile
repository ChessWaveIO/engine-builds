FROM alpine:3.20 AS fetch

ARG ASSET_URL=https://github.com/pkrisz99/Renegade/releases/download/v1.2.0/Renegade_1.2.0_linux_x86-64-bmi2
ARG BINARY_NAME=Renegade_1.2.0_linux_x86-64-bmi2
ARG LICENSE_URL=https://raw.githubusercontent.com/pkrisz99/Renegade/main/LICENSE
ARG SOURCE_REF=v1.2.0

RUN apk add --no-cache curl
RUN set -eux; \
    mkdir -p /out /tmp/asset; \
    curl -fsSL "$ASSET_URL" -o /tmp/asset/download; \
    cp /tmp/asset/download "/out/$BINARY_NAME"; \
    chmod 0755 "/out/$BINARY_NAME"; \
    curl -fsSL "$LICENSE_URL" -o /out/LICENSE || true; \
    printf 'Engine: renegade\nPlatform: linux-x86_64\nSource ref: %s\nAsset: %s\n' "$SOURCE_REF" "$ASSET_URL" > /out/UPSTREAM.txt

FROM scratch AS export
COPY --from=fetch /out/ /
