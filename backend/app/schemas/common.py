"""通用 Schema"""
from pydantic import BaseModel


class ErrorResponse(BaseModel):
    code: str
    message: str
    request_id: str = ""


class SuccessResponse(BaseModel):
    status: str = "ok"
