FROM node:20 AS build

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

# Install make and Go (official binary, not Debian package), then build console
RUN apt-get update && apt-get install -y make curl \
    && curl -LO https://go.dev/dl/go1.23.0.linux-arm64.tar.gz \
    && rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.0.linux-arm64.tar.gz \
    && export PATH=$PATH:/usr/local/go/bin \
    && /usr/local/go/bin/go version \
    && make console

# Final image
FROM python:alpine

WORKDIR /app
COPY --from=build /app /app

EXPOSE 9090

CMD ["./console", "server"]