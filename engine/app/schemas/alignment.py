"""对齐操作 Schema"""
from pydantic import BaseModel, field_validator
from typing import Optional
from enum import Enum


class AlignmentOpType(str, Enum):
    POSTPONE = "postpone"
    ADVANCE = "advance"
    DELETE = "delete"
    INSERT = "insert"


class AlignmentOp(BaseModel):
    type: AlignmentOpType
    word: str  # 被操作的目标词（INSERT/POSTPONE 为要插入/移动的词，DELETE 为被删除的词）
    target: Optional[str] = None  # POSTPONE 时表示目标位置对应的词
    position: Optional[int] = None  # 操作发生的位置（词在原始序列中的索引）
    source: Optional[int] = None  # POSTPONE 时表示被移动词在原始序列中的位置

    @field_validator('type', mode='before')
    @classmethod
    def validate_type(cls, v):
        if isinstance(v, str):
            return v.lower()
        return v
