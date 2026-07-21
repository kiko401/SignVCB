"""逆向归一化 Schema"""
from pydantic import BaseModel
from typing import List


class NormalizeRequest(BaseModel):
    text: str
    num_options: int = 3


class NormalizeResponse(BaseModel):
    options: List[str]
