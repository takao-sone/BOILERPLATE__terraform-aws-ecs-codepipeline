pub struct ApiPath {
    pub prefix: String,
}

impl ApiPath {
    pub fn define(&self, following_path: String) -> String {
        String::from("/api/v1") + &self.prefix + &following_path
    }
}
