# Dockerfile — Cross-compile strace (static, LTO, stripped)
#
# Usage:
#   DOCKER_BUILDKIT=1 docker build --build-arg TARGET_ARCH=arm64 \
#       --target=binary --output=type=local,dest=out/ .

# ── Stage 1: Builder ──
FROM ubuntu:22.04 AS builder

ARG STRACE_VERSION=7.0

ENV DEBIAN_FRONTEND=noninteractive

# Install all cross-compilation toolchains in one layer so it is shared
# across builds for different architectures (better Docker cache reuse).
# A native gcc is also needed for autotools build-time test programs.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates make file xz-utils \
    gcc libc6-dev \
    gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
    gcc-arm-linux-gnueabihf libc6-dev-armhf-cross \
    gcc-i686-linux-gnu libc6-dev-i386-cross \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN curl -fsSL "https://github.com/strace/strace/releases/download/v${STRACE_VERSION}/strace-${STRACE_VERSION}.tar.xz" \
    | tar xJ

COPY scripts/build-strace.sh /build-strace.sh
ARG TARGET_ARCH=arm64
RUN bash /build-strace.sh "$STRACE_VERSION" "$TARGET_ARCH"

# ── Stage 2: Extract binary ──
FROM scratch AS binary
COPY --from=builder /build/out/strace /strace
