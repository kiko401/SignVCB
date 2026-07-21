"""Rewrite 相关 Schema"""
from pydantic import BaseModel
from typing import Optional, Dict, List


class RewriteRequest(BaseModel):
    text: str
    context: Optional[str] = None


class FirstPassData(BaseModel):
    text: str
    oov_status: bool


class RefinedPassData(BaseModel):
    text: str
    oov_map: Dict[str, str]
    nmm_hints: Dict[str, str]
    alignment_ops: List
