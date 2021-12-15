FROM public.ecr.aws/docker/library/rust:1.53.0 as builder
WORKDIR /app
# 0
RUN apt-get update -yqq && apt-get install -yqq cmake g++ && apt install -y tzdata
# 1
COPY ./Cargo.toml ./Cargo.toml
RUN mkdir src
RUN echo "fn main() {}" > src/main.rs
RUN cargo fetch
RUN cargo install --path .
RUN rm -f target/debug/deps/boilerplate*
# 2
COPY ./src ./src
COPY ./diesel.toml ./diesel.toml
# 3
RUN cargo build --release

FROM public.ecr.aws/debian/debian:buster-slim as boilerplate
RUN apt-get update && apt-get install -y libpq5 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/boilerplate /usr/local/bin/boilerplate
EXPOSE 8080
CMD ["boilerplate"]
