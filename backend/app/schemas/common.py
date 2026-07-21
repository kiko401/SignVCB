"""通用 Schema"""
from pydantic import BaseModel


class ErrorResponse(BaseModel):
    error: str
    detail: str
    request_id: str = ""


class SuccessResponse(BaseModel):
    status: str = "ok"
