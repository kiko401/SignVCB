"""LLM 精炼模块"""
import loguru

logger = loguru.logger


class LLMRefiner:
    """使用 DeepSeek LLM 精炼 CSL 语序"""

    def __init__(self, llm_client):
        self.llm = llm_client

    async def refine(self, text: str, oov_map: dict = None) -> str:
        """精炼文本"""
        oov_info = ""
        if oov_map:
            oov_list = ", ".join([f"{k}->{v}" for k, v in oov_map.items()])
            oov_info = f"\n注意：以下词语已被降级：{oov_list}"

        prompt = f"""请将以下中文手语（CSL）文本按照自然中文语序调整。

CSL文本：{text}{oov_info}

要求：
1. 调整词序使其符合自然中文表达
2. 保持词语不变
3. 用空格分隔词语
4. 只返回调整后的文本，不要其他解释

调整后："""

        try:
            response = await self.llm.chat([
                {"role": "user", "content": prompt}
            ], temperature=0.3)

            refined = response.strip()
            return refined
        except Exception as e:
            logger.error(f"LLM refine failed: {e}")
            return text
