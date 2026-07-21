"""练习相关 Schema"""
from typing import Optional, Union, List
from pydantic import BaseModel


class PracticeQuestionResponse(BaseModel):
    id: int
    level: str
    type: str
    mode: Optional[str] = None
    image_urls: list[str] = []
    text: Optional[str] = None
    choices: list[str] = []
    scrambled: list[str] = []
    target_text: Optional[str] = None


class PracticeValidateRequest(BaseModel):
    question_id: int
    answer: Union[List[str], str]


class PracticeValidateResponse(BaseModel):
    correct: bool
    feedback: str
