use actix_web::web;

use crate::api::path::ApiPath;

pub mod get;

pub fn tests_factory(app: &mut web::ServiceConfig) {
    let base_path = ApiPath {
        prefix: String::from("/tests")
    };

    app.route(&base_path.define(String::from("")),
              web::get().to(get::handler));
}
