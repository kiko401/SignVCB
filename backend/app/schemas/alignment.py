"""对齐操作 Schema"""
from pydantic import BaseModel, field_validator
from enum import Enum
from typing import Optional


class AlignmentOpType(str, Enum):
    POSTPONE = "postpone"
    ADVANCE = "advance"
    DELETE = "delete"
    INSERT = "insert"


class AlignmentOp(BaseModel):
    type: AlignmentOpType
    word: str
    target: Optional[str] = None
    position: Optional[int] = None
    source: Optional[int] = None  # 仅 POSTPONE 时有

    @field_validator('type', mode='before')
    @classmethod
    def validate_type(cls, v):
        if isinstance(v, str):
            return v.lower()
        return v
