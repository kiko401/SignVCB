"""FastAPI 依赖注入"""
from fastapi import Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import decode_token
from app.core.exceptions import AuthInvalidError
from app.models.user import User
from sqlalchemy import select

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    session: AsyncSession = Depends(get_db)
) -> User:
    """获取当前登录用户"""
    token = credentials.credentials

    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            raise AuthInvalidError(detail="Invalid token")
    except Exception:
        raise AuthInvalidError(detail="Invalid token")

    result = await session.execute(
        select(User).where(User.id == int(user_id))
    )
    user = result.scalar_one_or_none()

    if not user:
        raise AuthInvalidError(detail="User not found")

    return user
