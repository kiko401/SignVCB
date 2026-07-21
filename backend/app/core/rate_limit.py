"""限流配置"""
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

RATE_LIMITS = {
    "auth_register": "5/minute",
    "auth_login": "5/minute",
    "chat_asr_rewrite": "15/minute",
    "chat_rewrite": "30/minute",
    "chat_tts": "30/minute",
    "chat_suggest": "30/minute",
    "chat_normalize": "30/minute",
    "chat_log_mismatch": "30/minute",
    "reading_books": "60/minute",
    "reading_content": "60/minute",
    "practice_question": "30/minute",
    "practice_validate": "30/minute",
    "app_config": "60/minute",
}
