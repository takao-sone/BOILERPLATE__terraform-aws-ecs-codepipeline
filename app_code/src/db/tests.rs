use diesel::prelude::*;
use crate::db::pagination::*;

use crate::db::connection::PooledConn;
use crate::diesel;
use crate::models::tests::Test;

pub fn find_tests(
    conn: &PooledConn,
    o_page: Option<i64>,
    o_per_page: Option<i64>,
) -> Result<(Vec<Test>, i64), diesel::result::Error> {
    use crate::schema::tests::dsl::*;

    let page = match o_page {
        Some(page) => page,
        None => 1,
    };

    let mut query = tests
        .select((id, name))
        .order(id.desc())
        .paginate(page);

    if let Some(per_page) = o_per_page {
        query = query.per_page(per_page);
    }

    let tests_and_total_pages = query.load_and_count_pages::<Test>(conn)?;

    Ok(tests_and_total_pages)
}
