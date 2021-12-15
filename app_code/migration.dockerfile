FROM clux/diesel-cli:latest as builder
WORKDIR /app
COPY ./migrations ./migrations
CMD ["diesel", "migration", "run"]
