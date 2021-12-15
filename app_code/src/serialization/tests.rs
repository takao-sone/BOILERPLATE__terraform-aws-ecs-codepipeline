use serde::Serialize;

#[derive(Serialize)]
pub struct GetTestsResponse {
    pub tests: Vec<ResponseTest>,
}

#[derive(Serialize)]
pub struct ResponseTest {
    pub id: i32,
    pub name: String,
}