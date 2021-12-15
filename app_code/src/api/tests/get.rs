use actix_web::{HttpRequest, HttpResponse, web};

use crate::db::connection::PgPool;
use crate::db::tests::find_tests;
use crate::error::AppError;
use crate::serialization::tests::{GetTestsResponse, ResponseTest};

pub async fn handler(
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    // Get tests
    let conn = pool.get()?;
    let result = web::block(move || find_tests(&conn, None, None)).await?;

    let response_test: Vec<ResponseTest> = result.0
        .into_iter()
        .map(|v| ResponseTest {
                id: v.id,
                name: v.name
            }
        ).collect();
    let get_tests_response = GetTestsResponse {
        tests: response_test
    };

    Ok(HttpResponse::Ok().json(get_tests_response))
}
