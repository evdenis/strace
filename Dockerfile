# Dockerfile — Cross-compile strace for ARM64 (static, LTO, stripped)
#
# Usage:
#   DOCKER_BUILDKIT=1 docker build --target=binary --output=type=local,dest=out/ .

# ── Stage 1: Builder ──
FROM ubuntu:22.04 AS builder

ARG STRACE_VERSION=5.9

ENV DEBIAN_FRONTEND=noninteractive

# Install cross-compilation toolchain.  gcc-aarch64-linux-gnu provides the
# cross-compiler and a complete aarch64 sysroot (glibc + kernel headers).
# A native gcc is also needed for autotools build-time test programs.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates make file xz-utils \
    gcc libc6-dev \
    gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN curl -fsSL "https://github.com/strace/strace/releases/download/v${STRACE_VERSION}/strace-${STRACE_VERSION}.tar.xz" \
    | tar xJ

COPY build-strace.sh /build-strace.sh
RUN bash /build-strace.sh "$STRACE_VERSION"

# ── Stage 2: Extract binary ──
FROM scratch AS binary
COPY --from=builder /build/out/strace /strace
