"""算法引擎配置"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", frozen=False)

    # DeepSeek
    DEEPSEEK_API_KEY: str = ""
    DEEPSEEK_BASE_URL: str = "https://api.deepseek.com/v1"
    DEEPSEEK_MODEL: str = "deepseek-v4-flash"
    DEEPSEEK_TIMEOUT: float = 4.0

    # ONNX 模型
    MODEL_PATH: str = "/app/models/csl_encoder.onnx"
    FAISS_INDEX_PATH: str = "/app/data/faiss/faiss_index.bin"
    VOCAB_PATH: str = "/app/data/vocab.json"
    INITIAL_FALLBACK_PATH: str = "/app/data/fallback/initial_fallback.json"

    # OOV 检测
    OOV_SIMILARITY_THRESHOLD: float = 0.8

    # Redis
    REDIS_HOST: str = "signvcb-redis"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0

    # 动态降级同步
    DYNAMIC_FALLBACK_SYNC_INTERVAL: int = 600

    # Backend (for dynamic fallback sync)
    BACKEND_HOST: str = "signvcb-server"
    BACKEND_PORT: int = 8000


@lru_cache()
def get_settings() -> Settings:
    return Settings()
