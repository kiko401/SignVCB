"""练习服务"""
from typing import Union, List, Optional
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
import json
from app.models.practice import PracticeQuestion
from app.schemas.practice import PracticeQuestionResponse


class PracticeService:
    """练习服务"""

    @staticmethod
    async def get_random_question(
        session: AsyncSession,
        level: str = None,
        type: str = None
    ) -> Optional[PracticeQuestionResponse]:
        """获取随机练习题"""
        stmt = select(PracticeQuestion)

        if level:
            stmt = stmt.where(PracticeQuestion.level == level)
        if type:
            stmt = stmt.where(PracticeQuestion.type == type)

        stmt = stmt.order_by(func.rand()).limit(1)

        result = await session.execute(stmt)
        q = result.scalar_one_or_none()

        if not q:
            return None

        question_data = json.loads(q.question) if q.question else {}

        return PracticeQuestionResponse(
            id=q.id,
            level=q.level,
            type=q.type,
            mode=question_data.get('mode'),
            image_urls=question_data.get('image_urls', []),
            text=question_data.get('text'),
            choices=question_data.get('choices', []),
            scrambled=question_data.get('scrambled', []),
            target_text=question_data.get('target_text'),
        )

    @staticmethod
    async def validate_answer(
        session: AsyncSession,
        question_id: int,
        answer: Union[List[str], str]
    ) -> tuple[bool, Union[List[str], str]]:
        """验证答案"""
        result = await session.execute(
            select(PracticeQuestion).where(PracticeQuestion.id == question_id)
        )
        q = result.scalar_one_or_none()

        if not q:
            return False, []

        correct_answer = json.loads(q.answer) if q.answer else []

        if isinstance(answer, list):
            correct = sorted(answer) == sorted(correct_answer)
        else:
            correct = answer == correct_answer

        return correct, correct_answer
