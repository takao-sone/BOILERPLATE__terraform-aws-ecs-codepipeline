#[macro_use]
extern crate diesel;
#[macro_use]
extern crate serde_json;

extern crate dotenv;

pub mod api;
pub mod app_middleware;
pub mod db;
mod error;
