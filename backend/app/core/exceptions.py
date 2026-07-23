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


class NotFoundError(AppException):
    def __init__(self, detail: str = "Resource not found"):
        super().__init__(404, detail, "NOT_FOUND")


class InternalError(AppException):
    def __init__(self, detail: str = "Internal server error"):
        super().__init__(500, detail, "INTERNAL_ERROR")


async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": exc.error_code,
            "message": exc.detail,
            "request_id": request.headers.get("X-Request-ID", ""),
        },
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """处理 FastAPI 原生 HTTPException，确保格式统一为 {code, message, request_id}"""
    code_map = {
        400: "VALIDATION_ERROR",
        401: "AUTH_INVALID",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        422: "VALIDATION_ERROR",
        429: "RATE_LIMITED",
        500: "INTERNAL_ERROR",
    }
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": code_map.get(exc.status_code, "UNKNOWN_ERROR"),
            "message": exc.detail,
            "request_id": request.headers.get("X-Request-ID", ""),
        },
    )


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(
        status_code=500,
        content={
            "code": "INTERNAL_ERROR",
            "message": "An unexpected error occurred",
            "request_id": request.headers.get("X-Request-ID", ""),
        },
    )


def register_exception_handlers(app):
    app.add_exception_handler(AppException, app_exception_handler)
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(Exception, generic_exception_handler)
