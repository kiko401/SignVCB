import sys
import loguru
from app.core.middleware import get_request_id

logger = loguru.logger


def init_logging():
    logger.remove()
    logger.add(
        sys.stdout,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{extra[request_id]}</cyan> | <level>{message}</level>",
        level="INFO",
    )
    logger.add(
        "/data/logs/app.log",
        rotation="100 MB",
        retention="7 days",
        level="DEBUG",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {extra[request_id]} | {message}",
    )


class LoggerCtx:
    def __init__(self, request_id: str = ""):
        self.request_id = request_id or get_request_id()

    def __enter__(self):
        logger.configure(extra={"request_id": self.request_id})
        return self

    def __exit__(self, *args):
        pass


def get_logger():
    return logger
