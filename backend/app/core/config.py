from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # JWT
    JWT_SECRET: str = ""
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 24 * 7

    # MySQL
    MYSQL_HOST: str = "signvcb-mysql"
    MYSQL_PORT: int = 3306
    MYSQL_USER: str = "signvcb"
    MYSQL_PASSWORD: str = ""
    MYSQL_DATABASE: str = "signvcb"

    # Redis
    REDIS_HOST: str = "signvcb-redis"
    REDIS_PORT: int = 6379

    # Algorithm Engine
    ALGORITHM_ENGINE_URL: str = "http://signvcb-engine:8001"
    ENGINE_HOST: str = "signvcb-engine"
    ENGINE_PORT: int = 8001
    ENGINE_TIMEOUT: float = 10.0
    ENGINE_CONNECT_TIMEOUT: float = 2.0

    # Tencent ASR
    TENCENT_ASR_SECRET_ID: str = ""
    TENCENT_ASR_SECRET_KEY: str = ""

    # MiniMax TTS
    MINIMAX_API_KEY: str = ""
    MINIMAX_GROUP_ID: str = ""

    # DeepSeek
    DEEPSEEK_API_KEY: str = ""
    DEEPSEEK_BASE_URL: str = "https://api.deepseek.com/v1"
    DEEPSEEK_MODEL: str = "deepseek-v4-flash"

    # Business switches
    ENABLE_STREAM_MASKING: bool = True
    SHOW_OOV_MAP: bool = True
    SHOW_NMM_HINTS: bool = True
    SSE_TIMEOUT_MS: int = 10000

    # Server
    SERVER_PUBLIC_HOST: str = "http://localhost:8081"
    TTS_AUDIO_DIR: str = "/data/tts_audio"

    # CORS
    CORS_ALLOW_ORIGINS: list[str] = ["*"]

    @property
    def DATABASE_URL(self) -> str:
        return f"mysql+aiomysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
