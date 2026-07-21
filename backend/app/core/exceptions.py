from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse


class AppException(HTTPException):
    def __init__(self, status_code: int, detail: str, error_code: str):
        super().__init__(status_code=status_code, detail=detail)
        self.error_code = error_code


class AuthInvalidError(AppException):
    def __init__(self, detail: str = "Invalid credentials"):
        super().__init__(401, detail, "AUTH_INVALID")


class RateLimitedError(AppException):
    def __init__(self, detail: str = "Rate limit exceeded"):
        super().__init__(429, detail, "RATE_LIMITED")


class EngineTimeoutError(AppException):
    def __init__(self, detail: str = "Algorithm engine timeout"):
        super().__init__(504, detail, "ENGINE_TIMEOUT")


class EngineUnavailableError(AppException):
    def __init__(self, detail: str = "Algorithm engine unavailable"):
        super().__init__(503, detail, "ENGINE_UNAVAILABLE")


class ASRFailedError(AppException):
    def __init__(self, detail: str = "ASR service failed"):
        super().__init__(502, detail, "ASR_FAILED")


class ValidationError(AppException):
    def __init__(self, detail: str = "Validation error"):
        super().__init__(400, detail, "VALIDATION_ERROR")


class InternalError(AppException):
    def __init__(self, detail: str = "Internal server error"):
        super().__init__(500, detail, "INTERNAL_ERROR")


async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.error_code,
            "detail": exc.detail,
            "request_id": request.headers.get("X-Request-ID", ""),
        },
    )


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(
        status_code=500,
        content={
            "error": "INTERNAL_ERROR",
            "detail": "An unexpected error occurred",
            "request_id": request.headers.get("X-Request-ID", ""),
        },
    )


def register_exception_handlers(app):
    app.add_exception_handler(AppException, app_exception_handler)
    app.add_exception_handler(Exception, generic_exception_handler)
