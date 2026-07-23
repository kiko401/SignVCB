"""健康检查"""
from fastapi import APIRouter
import loguru

logger = loguru.logger

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health():
    """健康检查

    返回 healthy/degraded 状态：
    - healthy：ONNX + FAISS 均可用，核心 pipeline 可运行
    - degraded：ONNX 或 FAISS 不可用，部分功能受限（向量检索不可用）
    """
    from app.core.onnx_encoder import ONNXEncoder
    encoder = ONNXEncoder.get_instance()
    onnx_ok = encoder.is_loaded()

    from app.pipelines.forward_rewrite import forward_rewrite_pipeline
    faiss_ok = forward_rewrite_pipeline.oov_detector.index is not None
    rewrite_pipeline_ok = forward_rewrite_pipeline._initialized

    from app.pipelines.reverse_normalize import reverse_normalize_pipeline
    normalize_ok = reverse_normalize_pipeline.llm is not None

    from app.core.llm_client import get_shared_client
    llm_ok = get_shared_client() is not None

    from app.services.dynamic_fallback_service import get_dynamic_fallback_service
    service = get_dynamic_fallback_service()
    dict_ok = service is not None and len(service.fallback_dict) > 0

    # 核心依赖（ONNX + FAISS）必须正常才算 healthy
    status = "healthy" if (onnx_ok and faiss_ok) else "degraded"

    return {
        "status": status,
        "dependencies": {
            "onnx": "ok" if onnx_ok else "error",
            "faiss": "ok" if faiss_ok else "error",
            "llm": "ok" if llm_ok else "error",
            "rewrite_pipeline": "ok" if rewrite_pipeline_ok else "error",
            "normalize_pipeline": "ok" if normalize_ok else "error",
            "dynamic_dict": "ok" if dict_ok else "not_loaded"
        }
    }
