"""逆向归一化流水线"""
from typing import List
import loguru

from app.core.llm_client import get_shared_client

logger = loguru.logger


class ReverseNormalizePipeline:
    """CSL 逆向归一化"""

    def __init__(self):
        self.llm = None

    def initialize(self):
        self.llm = get_shared_client()
        logger.info("ReverseNormalizePipeline initialized")

    async def normalize(self, text: str, num_options: int = 3) -> List[str]:
        """将 CSL 文本逆向归一化为自然中文"""
        if not self.llm:
            logger.warning("ReverseNormalizePipeline not initialized, initializing now...")
            self.initialize()

        prompt = f"""请将以下 CSL（中文手语）文本转换为自然中文句子。

CSL文本：{text}

要求：
1. 保持原意
2. 生成 {num_options} 个不同的候选
3. 每个候选一行
4. 只返回候选句子，不要编号

候选："""

        try:
            response = await self.llm.chat([
                {"role": "user", "content": prompt}
            ], temperature=0.8)

            options = [line.strip() for line in response.split("\n") if line.strip()]
            return options[:num_options]
        except Exception as e:
            logger.error(f"Normalize failed: {e}")
            return [text]


reverse_normalize_pipeline = ReverseNormalizePipeline()
