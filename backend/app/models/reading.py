from sqlalchemy import Column, Integer, String, Text, ForeignKey
from app.core.database import Base


class ReadingBook(Base):
    __tablename__ = "reading_books"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(100), nullable=False)
    age_group = Column(String(10), nullable=False)
    cover_url = Column(String(500), nullable=True)
    difficulty = Column(Integer, default=1)


class ReadingSentence(Base):
    __tablename__ = "reading_sentences"

    id = Column(Integer, primary_key=True, autoincrement=True)
    book_id = Column(Integer, ForeignKey("reading_books.id"), nullable=False, index=True)
    sentence_index = Column(Integer, nullable=False)
    original_text = Column(Text, nullable=False)
    sign_text = Column(Text, nullable=False)
    alignment_ops = Column(Text, nullable=True)
