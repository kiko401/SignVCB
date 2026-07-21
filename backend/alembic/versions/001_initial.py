"""Initial migration - create all tables

Revision ID: 001_initial
Revises:
Create Date: 2024-01-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '001_initial'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('username', sa.String(length=50), nullable=False),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('age_group', sa.String(length=10), nullable=False),
        sa.Column('nickname', sa.String(length=100), nullable=True),
        sa.Column('avatar_url', sa.String(length=500), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('username'),
    )
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)

    op.create_table(
        'reading_books',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('title', sa.String(length=100), nullable=False),
        sa.Column('age_group', sa.String(length=10), nullable=False),
        sa.Column('cover_url', sa.String(length=500), nullable=True),
        sa.Column('difficulty', sa.Integer(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table(
        'reading_sentences',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('book_id', sa.Integer(), nullable=False),
        sa.Column('sentence_index', sa.Integer(), nullable=False),
        sa.Column('original_text', sa.Text(), nullable=False),
        sa.Column('sign_text', sa.Text(), nullable=False),
        sa.Column('alignment_ops', sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(['book_id'], ['reading_books.id'], ),
        sa.Index('ix_reading_sentences_book_id', 'book_id'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table(
        'practice_questions',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('level', sa.String(length=10), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('question', sa.Text(), nullable=False),
        sa.Column('answer', sa.Text(), nullable=False),
        sa.Index('ix_practice_questions_level', 'level'),
        sa.Index('ix_practice_questions_type', 'type'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table(
        'practice_records',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('question_id', sa.Integer(), nullable=False),
        sa.Column('correct', sa.Boolean(), nullable=False),
        sa.Column('answered_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['question_id'], ['practice_questions.id'], ),
        sa.Index('ix_practice_records_user_id', 'user_id'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table(
        'dynamic_fallback',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('oov_word', sa.String(length=50), nullable=False),
        sa.Column('fallback_word', sa.String(length=50), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Index('ix_dynamic_fallback_oov_word', 'oov_word'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('oov_word'),
    )

    op.create_table(
        'intent_mismatch_logs',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('original_text', sa.Text(), nullable=False),
        sa.Column('failed_options', sa.Text(), nullable=False),
        sa.Column('context', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.Index('ix_intent_mismatch_logs_user_id', 'user_id'),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    op.drop_table('intent_mismatch_logs')
    op.drop_table('dynamic_fallback')
    op.drop_table('practice_records')
    op.drop_table('practice_questions')
    op.drop_table('reading_sentences')
    op.drop_table('reading_books')
    op.drop_table('users')
