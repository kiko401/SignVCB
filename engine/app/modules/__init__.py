"""Modules 模块（延迟导入，避免 jieba 等可选依赖强绑定）"""

__all__ = [
    "OOVDetector",
    "FallbackResolver",
    "LLMRefiner",
    "AlignmentGenerator",
    "NMMGenerator",
]
