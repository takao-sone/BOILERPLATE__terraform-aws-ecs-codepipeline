use std::task::{Context, Poll};

use actix_service::{Service, Transform};
use actix_web::{dev::ServiceRequest, dev::ServiceResponse, Error, HttpResponse};
use futures::future::{ok, Either, Ready};
use std::rc::Rc;

pub struct CSRF(Rc<Inner>);

struct Inner {
    pub valid_origin: String,
    pub valid_referer: String,
}

impl CSRF {
    pub fn new(valid_origin_arg: String, valid_referer_arg: String) -> CSRF {
        CSRF(Rc::new(Inner {
            valid_origin: valid_origin_arg,
            valid_referer: valid_referer_arg,
        }))
    }
}

impl<S, B> Transform<S> for CSRF
where
    S: Service<Request = ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Request = ServiceRequest;
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Transform = CSRFMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ok(CSRFMiddleware {
            service,
            valid_origin: (&self.0.valid_origin).to_string(),
            valid_referer: (&self.0.valid_referer).to_string(),
        })
    }
}

pub struct CSRFMiddleware<S> {
    service: S,
    valid_origin: String,
    valid_referer: String,
}

impl<S, B> Service for CSRFMiddleware<S>
where
    S: Service<Request = ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Request = ServiceRequest;
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = Either<S::Future, Ready<Result<Self::Response, Self::Error>>>;

    fn poll_ready(&mut self, cx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        self.service.poll_ready(cx)
    }

    fn call(&mut self, req: ServiceRequest) -> Self::Future {
        let req_method = req.method().as_str();

        if (req_method == "GET") | (req_method == "OPTIONS") {
            return Either::Left(self.service.call(req));
        }

        let opt_origin = req.headers().get("origin");

        match opt_origin {
            Some(origin) => {
                let origin_value: &str = origin.to_str().expect("Failed to get origin value.");

                if origin_value == (&self.valid_origin) {
                    return Either::Left(self.service.call(req));
                }

                log::error!("BadRequest: No VALID Origin header.");
                return Either::Right(ok(req.into_response(
                    HttpResponse::BadRequest()
                        .json(json!({
                            "message": "BadRequest from middleware."
                        }))
                        .into_body(),
                )));
            }
            None => {
                let opt_referer = req.headers().get("referer");

                match opt_referer {
                    Some(referer) => {
                        let referer_value: &str =
                            referer.to_str().expect("Failed to get referer value.");

                        if referer_value.starts_with(&self.valid_referer) {
                            return Either::Left(self.service.call(req));
                        }

                        log::error!("BadRequest: No VALID Referer header.");
                        Either::Right(ok(req.into_response(
                            HttpResponse::BadRequest()
                                .json(json!({
                                    "message": "BadRequest from middleware."
                                }))
                                .into_body(),
                        )))
                    }
                    None => {
                        log::error!("BadRequest: No Referer header.");
                        Either::Right(ok(req.into_response(
                            HttpResponse::BadRequest()
                                .json(json!({
                                    "message": "BadRequest from middleware."
                                }))
                                .into_body(),
                        )))
                    }
                }
            }
        }
    }
}
