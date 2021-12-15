extern crate dotenv;

use std::env;

use actix_cors::Cors;
use actix_redis::{RedisSession, SameSite};
use actix_web::http::header;
use actix_web::{middleware, App, HttpServer};
use boilerplate::api;
use boilerplate::app_middleware;
use boilerplate::db::connection::new_pool;
use env_logger;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // std::env::set_var("RUST_LOG", "actix_server=info,actix_web=info");
    // std::env::set_var("RUST_LOG", "actix_web=debug");
    // std::env::set_var("RUST_LOG", "info");
    std::env::set_var("RUST_LOG", "debug");
    std::env::set_var("RUST_BACKTRACE", "1");
    env_logger::init();
    dotenv::dotenv().ok();

    // Command line args (for Test)
    let command_line_args: Vec<String> = env::args().collect();
    let run_environment = if command_line_args.len() > 1 {
        &command_line_args[1]
    } else {
        "dev"
    };

    // DB & Connection Pooling
    let pool = new_pool(run_environment).expect("Failed to create pool.");

    // Redis
    let redis_address_port = if run_environment == "test" {
        env::var("TEST_REDIS_ADDRESS_PORT").expect("Failed to get test Redis address port.")
    } else {
        env::var("REDIS_ADDRESS_PORT").expect("Failed to get dev Redis address port.")
    };
    let private_key = env::var("REDIS_PRIVATE_KEY").expect("Failed to get Redis key.");

    // Cors
    let allowed_origin = env::var("FRONTEND_ORIGIN").expect("Failed to get frontend origin.");

    // Csrf
    let valid_referer_value =
        env::var("VALID_REFERER_VALUE").expect("Failed to get valid referer value.");
    let valid_origin_value =
        env::var("VALID_ORIGIN_VALUE").expect("Failed to get valid origin value.");

    // Bound address
    let bound_address = if run_environment == "test" {
        env::var("TEST_BOUND_ADDRESS").expect("Failed to get test bound address.")
    } else {
        env::var("BOUND_ADDRESS").expect("Failed to get dev bound address.")
    };

    // Main Server
    HttpServer::new(move || {
        App::new()
            .data(pool.clone())
            .wrap(
                RedisSession::new(redis_address_port.as_str(), &private_key.as_bytes())
                    .ttl(60 * 60 * 24 * 3) // 3 days
                    .cookie_name("session")
                    .cookie_same_site(SameSite::Lax)
                    .cache_keygen(Box::new(|key: &str| format!("{}", &key)))
                    .cookie_max_age(time::Duration::days(3))
                    .cookie_http_only(true)
                    // TODO: when in production, it has to be TRUE.
                    // .cookie_secure(true),
                    .cookie_secure(false),
            )
            .wrap(
                Cors::default()
                    .allowed_origin(&allowed_origin)
                    .allowed_methods(vec!["GET", "POST", "DELETE"])
                    .allowed_headers(vec![header::AUTHORIZATION, header::ACCEPT])
                    .allowed_header(header::CONTENT_TYPE)
                    .supports_credentials()
                    .max_age(3600),
            )
            .wrap(app_middleware::csrf::CSRF::new(
                valid_origin_value.clone(),
                valid_referer_value.clone(),
            ))
            .wrap(middleware::Logger::default())
            .configure(api::api_factory)
    })
    .bind(bound_address)?
    .run()
    .await
}
