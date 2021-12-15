use actix_web::web;

mod app;
mod path;
mod tests;

pub fn api_factory(app: &mut web::ServiceConfig) {
    app::app_factory(app);
    tests::tests_factory(app);
}
