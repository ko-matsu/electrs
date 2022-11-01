# バイナリを alpine で動作させるために rust:1.64.0 でなく rust:1.64.0-alpine でビルドする
FROM --platform=$TARGETPLATFORM rust:1.64.0-alpine3.15 as electrs_builder
COPY . /app
ENV RUSTFLAGS="-Ctarget-feature=-crt-static"
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      export RUST_TOOLCHAIN=1.64.0-aarch64-unknown-linux-musl ;\
    else \
      export RUST_TOOLCHAIN=1.64.0-x86_64-unknown-linux-musl ;\
    fi && \
    apk add git clang cmake && \
    # rust:1.64.0-alpine でビルドするのに必要なパッケージ
    apk add gcc g++ linux-headers llvm-dev musl-dev musl-utils && \
    rustup component add rustfmt --toolchain $RUST_TOOLCHAIN && \
    cd /app && \
    cargo build --release --features liquid --bin electrs

FROM alpine:3.15 as electrs
RUN apk add gcc libstdc++
COPY --from=electrs_builder /app/target/release/electrs /bin
CMD ["sh", "-c", "electrs -vvvv --network=liquidregtest"]
