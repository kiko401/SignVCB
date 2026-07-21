"""应用配置 Schema"""
from pydantic import BaseModel


class AppConfigResponse(BaseModel):
    enable_stream_masking: bool
    show_oov_map: bool
    show_nmm_hints: bool
    sse_timeout_ms: int
