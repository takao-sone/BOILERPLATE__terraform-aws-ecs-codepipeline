use actix_web::web;

mod app;
mod path;

pub fn api_factory(app: &mut web::ServiceConfig) {
    app::app_factory(app);
}
