"""NMM（非手态标记）生成模块"""
from typing import Dict

NEGATION_WORDS = {"不", "没", "无", "非", "别", "莫", "休", "未曾", "不会", "不能"}
QUESTION_WORDS = {"吗", "呢", "吧", "呀", "啊", "哦", "嘛", "哪", "谁", "什么", "怎么", "为什么"}
PAUSE_WORDS = {"，", "。", "、", "；", "：", "...", "…", "（", "）", "[", "]"}


class NMMGenerator:
    """生成 NMM（非手态标记）标识"""

    def generate(self, text: str) -> Dict[str, str]:
        """生成 NMM 标识"""
        import jieba
        hints = {}
        words = list(jieba.cut(text))

        for word in words:
            if word in NEGATION_WORDS:
                hints[word] = "NEGATION"
            elif word in QUESTION_WORDS:
                hints[word] = "QUESTION"
            elif word in PAUSE_WORDS:
                hints[word] = "PAUSE"

        return hints
