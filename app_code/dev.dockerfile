#FROM rust:1.53.0
#
#WORKDIR /app
#
## 0
#RUN apt-get update -yqq \
#    && apt-get install -yqq cmake g++ \
#    && apt install -y tzdata
#ENV TZ=Asia/Tokyo
#
## 1
##RUN cargo install diesel_cli --no-default-features --features postgres
#
## 2
#COPY ./Cargo.toml ./Cargo.toml
##RUN mkdir src
##RUN echo "fn main() {}" > src/main.rs
##RUN cargo fetch
##RUN cargo install --path .
##RUN rm -f target/debug/deps/boilerplate_actix-web_postgres*
#
## 3
##COPY ./migrations ./migrations
#COPY ./src ./src
#COPY ./.env ./.env
##COPY ./diesel.toml ./diesel.toml
#
## 4
#RUN cargo build --release
#
#EXPOSE 8080
#
#CMD ["cargo", "run", "--release"]
##CMD ["cargo", "run"]
##ENTRYPOINT ["boilerplate_actix-web_postgres"]
##ENTRYPOINT ["./target/release/boilerplate_actix-web_postgres"]

#########################################################
# 軽量版

FROM rust:1.53.0 as builder
WORKDIR /app
# 0
RUN apt-get update -yqq && apt-get install -yqq cmake g++ && apt install -y tzdata
RUN cargo install diesel_cli --no-default-features --features postgres
# 1
COPY ./Cargo.toml ./Cargo.toml
RUN mkdir src
RUN echo "fn main() {}" > src/main.rs
RUN cargo fetch
RUN cargo install --path .
RUN rm -f target/debug/deps/boilerplate*
# 2
COPY ./src ./src
COPY ./.env ./.env
#COPY ./migrations ./migrations
#COPY ./diesel.toml ./diesel.toml
# 3
RUN cargo build --release

FROM debian:buster-slim
RUN apt-get update && apt-get install -y libpq5 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/boilerplate /usr/local/bin/boilerplate
EXPOSE 80
CMD ["boilerplate"]