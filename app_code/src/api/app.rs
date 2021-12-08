use crate::api::path::ApiPath;
use actix_web::{web, HttpResponse};

async fn index() -> HttpResponse {
    HttpResponse::Ok().json("Hello!!!!!")
}

async fn index_post() -> HttpResponse {
    HttpResponse::Ok().json("POST!!!!!")
}

pub fn app_factory(app: &mut web::ServiceConfig) {
    let base_path = ApiPath {
        prefix: String::from(""),
    };

    app.route(&base_path.define(String::from("/")), web::get().to(index));
    app.route(
        &base_path.define(String::from("/")),
        web::post().to(index_post),
    );
}
