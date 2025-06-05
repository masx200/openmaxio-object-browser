FROM node:20 AS build

ARG TARGETARCH

WORKDIR /app

# Copy web-app and install/build
COPY web-app ./web-app
WORKDIR /app/web-app

# Enable Corepack and prepare Yarn 4
RUN corepack enable && corepack prepare yarn@4.4.0 --activate

RUN yarn install && yarn build

# Copy rest of the repo for make/console
WORKDIR /app
COPY . .

# Install make and Go (official binary, not Debian package), then build console and support buildx
RUN apt-get update && apt-get install -y make curl \
    && GO_VERSION=1.23.0 \
    && if [ "$TARGETARCH" = "amd64" ]; then GOARCH=amd64; else GOARCH=$TARGETARCH; fi \
    && curl -LO https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz \
    && rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-${GOARCH}.tar.gz \
    && export PATH=$PATH:/usr/local/go/bin \
    && /usr/local/go/bin/go version \
    && make console 

# Final image
FROM python:alpine

WORKDIR /app
COPY --from=build /app /app

EXPOSE 9090

CMD ["./console", "server"]