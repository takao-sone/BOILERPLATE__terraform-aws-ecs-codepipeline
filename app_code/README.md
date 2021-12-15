# Boilerplate

## Setup

Clone

```shell
git clone {this-repository}
```

Install dependencies

```shell
cargo install --path .
```

Configure the repo with git-secrets

```shell
cd /path/to/my/repo
git secrets --install
git secrets --register-aws
```

### Notice
If you encounter errors like `error: linking with cc failed: exit code: 1`, then **run the next command**

```shell
sudo xcode-select --reset
```

Run application

```shell
# Normal
cargo run

# Run Release version
cargo run --release

# Auto Reloading
cargo watch -x 'run --bin boilerplate_actix-web_postgres'

# test: Test transaction to DB
cargo run -- test
```

Docker compose

```shell
# dev environment
docker compose -f docker-compose.dev.yml -p dev up
docker compose -f docker-compose.dev.yml -p dev down
```