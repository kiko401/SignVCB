from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base


class DynamicFallback(Base):
    __tablename__ = "dynamic_fallback"

    id = Column(Integer, primary_key=True, autoincrement=True)
    oov_word = Column(String(50), unique=True, nullable=False, index=True)
    fallback_word = Column(String(50), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class IntentMismatchLog(Base):
    __tablename__ = "intent_mismatch_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    original_text = Column(Text, nullable=False)
    failed_options = Column(Text, nullable=False)
    context = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
