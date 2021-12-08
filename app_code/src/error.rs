use actix_web::error::BlockingError;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, ResponseError};
use derive_more::Display;
use diesel::r2d2::PoolError;
use diesel::result::{DatabaseErrorKind, Error as DieselError};
use serde_json::{Map as JsonMap, Value as JsonValue};
use validator::ValidationErrors;
// use bcrypt::BcryptError;

#[derive(Debug, Display)]
pub enum AppError {
    // 400
    #[display(fmt = "Bad Request Error")]
    BadRequest(JsonValue),
    // 401
    #[allow(dead_code)]
    #[display(fmt = "Unauthorized Error")]
    Unauthorized(JsonValue, HttpRequest),
    // 403
    #[allow(dead_code)]
    #[display(fmt = "Forbidden Error")]
    Forbidden(JsonValue),
    // 404
    #[display(fmt = "Not Found Error")]
    NotFound(JsonValue),
    // 409
    #[display(fmt = "Conflict Error: {}", _0)]
    Conflict(JsonValue),
    // 422
    #[allow(dead_code)]
    #[display(fmt = "Unprocessable Entity Error: {}", _0)]
    UnprocessableEntity(JsonValue),
    // 500
    #[display(fmt = "Internal Server Error")]
    InternalServerError,
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        match self {
            AppError::BadRequest(message) => {
                log::error!("BadRequest: {:?}", message);
                HttpResponse::BadRequest().json(message)
            }
            AppError::Unauthorized(message, req) => {
                log::error!("Unauthorized: {:?}", message);
                match req.cookie("session") {
                    Some(mut cookie) => {
                        cookie.set_path("/");
                        HttpResponse::Unauthorized()
                            .del_cookie(&cookie)
                            .json(message)
                    }
                    None => HttpResponse::Unauthorized().json(message),
                }
            }
            AppError::Forbidden(message) => {
                log::error!("Forbidden: {:?}", message);
                HttpResponse::Forbidden().json(message)
            }
            AppError::NotFound(message) => {
                log::error!("NotFound: {:?}", message);
                HttpResponse::NotFound().json(message)
            }
            AppError::Conflict(message) => {
                log::error!("Conflict: {:?}", message);
                HttpResponse::Conflict().json(json!({
                    "error": "Conflict: already exists."
                }))
            }
            AppError::UnprocessableEntity(message) => {
                log::error!("UnprocessableEntity: {:?}", message);
                HttpResponse::UnprocessableEntity().json(message)
            }
            _ => {
                log::error!("InternalServerError");
                HttpResponse::InternalServerError().finish()
            }
        }
    }
}

impl From<DieselError> for AppError {
    fn from(error: DieselError) -> Self {
        log::error!("DieselError: {:?}", error);

        match error {
            DieselError::DatabaseError(kind, info) => {
                if let DatabaseErrorKind::UniqueViolation = kind {
                    let message = info.details().unwrap_or_else(|| info.message()).to_string();
                    return AppError::Conflict(json!({ "error": message }));
                }
                AppError::InternalServerError
            }
            DieselError::NotFound => AppError::NotFound(json!({ "error": "Resource not found" })),
            _ => AppError::InternalServerError,
        }
    }
}

impl From<ValidationErrors> for AppError {
    fn from(errors: ValidationErrors) -> Self {
        log::error!("ValidationErrors: {:?}", errors);

        let mut err_map = JsonMap::new();

        for (field, errors) in errors.field_errors().iter() {
            let errors: Vec<JsonValue> = errors.iter().map(|error| json!(error.message)).collect();
            err_map.insert(field.to_string(), json!(errors));
        }

        AppError::BadRequest(json!({
            "errors": err_map,
        }))
    }
}

impl From<PoolError> for AppError {
    fn from(error: PoolError) -> Self {
        log::error!("PoolError: {:?}", error);

        AppError::InternalServerError
    }
}

impl From<BlockingError<DieselError>> for AppError {
    fn from(error: BlockingError<DieselError>) -> Self {
        log::error!("BlockingError<DieselError>: {:?}", error);

        match error {
            BlockingError::Error(diesel_error) => AppError::from(diesel_error),
            _ => error.into(),
        }
    }
}

impl From<actix_web::Error> for AppError {
    fn from(error: actix_web::Error) -> Self {
        log::error!("actix_web::Error: {:?}", error);

        AppError::InternalServerError
    }
}

// impl From<BcryptError> for AppError {
//     fn from(error: BcryptError) -> Self {
//         log::error!("BcryptError: {:?}", error);
//
//         AppError::InternalServerError
//     }
// }
