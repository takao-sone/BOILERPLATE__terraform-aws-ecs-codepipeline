use diesel::pg::PgConnection;
use diesel::r2d2::{ConnectionManager, Pool, PoolError, PooledConnection};
use diesel::Connection;
use dotenv::dotenv;
use std::env;

pub type PgPool = Pool<ConnectionManager<PgConnection>>;
pub type PooledConn = PooledConnection<ConnectionManager<PgConnection>>;

pub fn new_pool(run_environment: &str) -> Result<PgPool, PoolError> {
    dotenv().ok();

    let database_url = if run_environment == "test" {
        env::var("TEST_DATABASE_URL").expect("Failed to get test db address.")
    } else {
        env::var("DATABASE_URL").expect("Failed to get dev db address.")
    };

    let manager = ConnectionManager::<PgConnection>::new(database_url);
    let pool_size = match cfg!(test) {
        // MEMO: when tested, pool size should be set to 1 because of begin_test_transaction() method.
        true => 1,
        false => 10,
    };
    let pool = diesel::r2d2::Pool::builder()
        .max_size(pool_size)
        .build(manager)?;

    if run_environment == "test" {
        pool.get().unwrap().begin_test_transaction().unwrap();
    }

    Ok(pool)
}
