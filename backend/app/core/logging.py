import sys
import loguru
from app.core.middleware import get_request_id

logger = loguru.logger


class _RequestIdFormatter:
    """包装格式字符串，每次输出时从 ContextVar 取 request_id"""

    def __init__(self, fmt):
        self.fmt = fmt

    def format(self, record):
        record["extra"]["request_id"] = get_request_id()
        return self.fmt.format(**record)


def init_logging():
    logger.remove()
    logger.configure(extra={"request_id": ""})

    stdout_fmt = _RequestIdFormatter(
        "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{extra[request_id]}</cyan> | <level>{message}</level>"
    )
    file_fmt = _RequestIdFormatter(
        "{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {extra[request_id]} | {message}"
    )

    logger.add(sys.stdout, level="INFO", format=stdout_fmt.format)
    logger.add("/data/logs/app.log", rotation="100 MB", retention="7 days", level="DEBUG", format=file_fmt.format)


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
