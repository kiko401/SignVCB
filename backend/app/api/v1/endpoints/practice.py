"""练习接口"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.practice import PracticeQuestionResponse, PracticeValidateRequest, PracticeValidateResponse
from app.services.practice_service import PracticeService

router = APIRouter()


@router.get("/question", response_model=PracticeQuestionResponse)
async def get_question(
    level: str = None,
    q_type: str = None,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取随机练习题"""
    question = await PracticeService.get_random_question(session, level, q_type)
    if not question:
        return PracticeQuestionResponse(
            id=0, level="", type="", image_urls=[]
        )
    return question


@router.post("/validate", response_model=PracticeValidateResponse)
async def validate_answer(
    req: PracticeValidateRequest,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """验证答案"""
    correct, answer = await PracticeService.validate_answer(
        session, req.question_id, req.answer
    )
    return PracticeValidateResponse(correct=correct, correct_answer=answer)
