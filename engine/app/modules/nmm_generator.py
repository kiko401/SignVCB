"""NMM（非手态标记）生成模块"""
import jieba
from typing import Dict

NEGATION_WORDS = {"不", "没", "无", "非", "别", "莫", "休", "未曾", "不会", "不能"}
QUESTION_WORDS = {"吗", "呢", "吧", "呀", "啊", "哦", "嘛", "哪", "谁", "什么", "怎么", "为什么"}
PAUSE_WORDS = {"，", "。", "、", "；", "：", "...", "…", "（", "）", "[", "]"}


class NMMGenerator:
    """生成 NMM（非手态标记）标识"""

    def generate(self, text: str) -> Dict[str, str]:
        """生成 NMM 标识（key 为词在 CSL 序列中的位置索引）

        输入：如果 text 包含空格，先按空格分割（pipeline 传入的是 CSL 空格分隔文本）；
              否则用 jieba 分词（兼容未分词的原始文本）。

        例如输入 "我 苹果 吃 不"（CSL语序）：
          - 位置0: "我" → 无标记
          - 位置1: "苹果" → 无标记
          - 位置2: "吃" → 无标记
          - 位置3: "不" → NEGATION
        输出: {"3": "NEGATION"}
        """
        hints = {}

        # pipeline 传入的是空格分隔的 CSL 文本，直接 split
        if " " in text:
            words = text.split()
        else:
            words = list(jieba.cut(text))

        for idx, word in enumerate(words):
            if word in NEGATION_WORDS:
                hints[str(idx)] = "NEGATION"
            elif word in QUESTION_WORDS:
                hints[str(idx)] = "QUESTION"
            elif word in PAUSE_WORDS:
                hints[str(idx)] = "PAUSE"

        return hints
