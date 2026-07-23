"""LLM 精炼模块"""
import loguru

logger = loguru.logger

# CSL 语序规则说明
CSL_RULES = """CSL（中文手语）语序规则：
1. 主语 + 宾语 + 谓语（SOV 语序，如"我 苹果 吃"而非"我 吃 苹果"）
2. 时间词/地点词放在句首（如"明天 我 学校 去"）
3. 否定词放在动词之后（如"我 去 不"表示"我不去"）
4. 疑问词放在句末（如"你 名字 叫 什么"）
5. 修饰语放在被修饰词之前（如"大 苹果"）
6. 量词和虚词可省略（如"一个苹果"简化为"苹果"，"了"去掉）"""

# Few-shot 示例
FEW_SHOT = """示例：
输入：我吃苹果
输出：我 苹果 吃

输入：明天我去学校
输出：明天 我 学校 去

输入：你叫什么名字
输出：你 名字 叫 什么

输入：我不去
输出：我 去 不

输入：今天天气很好
输出：今天 天气 好 很

输入：那个人是谁
输出：那 个人 是 谁"""


class LLMRefiner:
    """使用 DeepSeek LLM 精炼 CSL 语序"""

    def __init__(self, llm_client):
        self.llm = llm_client

    async def refine(self, text: str, oov_map: dict = None) -> str:
        """将自然中文文本精炼为 CSL 语序"""
        oov_info = ""
        if oov_map:
            oov_list = ", ".join([f"{k}->{v}" for k, v in oov_map.items()])
            oov_info = f"\n注意：以下词语已被降级替换：{oov_list}"

        prompt = f"""你是一个中文手语（CSL）语序转换专家。请将输入的自然中文转换为CSL手语语序文本。

{CSL_RULES}

{FEW_SHOT}

{oov_info}

输入：{text}
输出："""

        try:
            response = await self.llm.chat(
                [{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=256,
            )
            # 清理 LLM 可能附加的多余内容，只取第一行
            refined = response.strip().split("\n")[0].strip().strip('"').strip("'")
            return refined
        except Exception as e:
            logger.error(f"LLM refine failed: {e}")
            return text  # 返回原始输入，由 pipeline 层决定回退到 first_pass_text
