"""对齐操作生成模块"""
from typing import List
from app.schemas.alignment import AlignmentOp, AlignmentOpType
import loguru

logger = loguru.logger


class AlignmentGenerator:
    """生成 CSL 文本对齐操作（使用 LCS 算法）"""

    def generate(self, original: str, refined: str) -> List[AlignmentOp]:
        """生成对齐操作列表"""
        orig_words = original.split()
        refined_words = refined.split()

        lcs = self._lcs(orig_words, refined_words)

        ops = []
        orig_idx = 0
        refined_idx = 0
        lcs_idx = 0

        while orig_idx < len(orig_words) or refined_idx < len(refined_words):
            if lcs_idx < len(lcs) and orig_idx < len(orig_words) and refined_idx < len(refined_words):
                orig_word = orig_words[orig_idx]
                refined_word = refined_words[refined_idx]
                lcs_word = lcs[lcs_idx]

                if orig_word == lcs_word and refined_word == lcs_word:
                    orig_idx += 1
                    refined_idx += 1
                    lcs_idx += 1
                elif orig_word == lcs_word:
                    ops.append(AlignmentOp(
                        type=AlignmentOpType.INSERT,
                        word=refined_word,
                        position=refined_idx
                    ))
                    refined_idx += 1
                elif refined_word == lcs_word:
                    ops.append(AlignmentOp(
                        type=AlignmentOpType.DELETE,
                        word=orig_word,
                        position=orig_idx
                    ))
                    orig_idx += 1
                else:
                    ops.append(AlignmentOp(
                        type=AlignmentOpType.POSTPONE,
                        word=orig_word,
                        target=refined_word,
                        position=orig_idx
                    ))
                    orig_idx += 1
                    refined_idx += 1
            else:
                if orig_idx < len(orig_words):
                    for w in orig_words[orig_idx:]:
                        ops.append(AlignmentOp(type=AlignmentOpType.DELETE, word=w, position=orig_idx))
                    break
                if refined_idx < len(refined_words):
                    for w in refined_words[refined_idx:]:
                        ops.append(AlignmentOp(type=AlignmentOpType.INSERT, word=w, position=refined_idx))
                    break

        return ops

    def _lcs(self, a: List[str], b: List[str]) -> List[str]:
        """计算最长公共子序列"""
        m, n = len(a), len(b)
        dp = [[0] * (n + 1) for _ in range(m + 1)]

        for i in range(1, m + 1):
            for j in range(1, n + 1):
                if a[i-1] == b[j-1]:
                    dp[i][j] = dp[i-1][j-1] + 1
                else:
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])

        lcs = []
        i, j = m, n
        while i > 0 and j > 0:
            if a[i-1] == b[j-1]:
                lcs.append(a[i-1])
                i -= 1
                j -= 1
            elif dp[i-1][j] > dp[i][j-1]:
                i -= 1
            else:
                j -= 1

        return list(reversed(lcs))
