use crate::schema::tests;

#[derive(Debug, Queryable, Identifiable)]
pub struct Test {
    pub id: i32,
    pub name: String,
}
