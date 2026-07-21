"""健康检查"""
from fastapi import APIRouter
import loguru

logger = loguru.logger

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health():
    """健康检查"""
    from app.core.onnx_encoder import ONNXEncoder
    encoder = ONNXEncoder.get_instance()
    onnx_ok = encoder.is_loaded()

    from app.pipelines.forward_rewrite import forward_rewrite_pipeline
    faiss_ok = forward_rewrite_pipeline.oov_detector.index is not None

    from app.services.dynamic_fallback_service import get_dynamic_fallback_service
    service = get_dynamic_fallback_service()
    dict_ok = service is not None and len(service.fallback_dict) > 0

    status = "healthy" if (onnx_ok and faiss_ok) else "degraded"

    return {
        "status": status,
        "dependencies": {
            "onnx": "ok" if onnx_ok else "error",
            "faiss": "ok" if faiss_ok else "error",
            "dynamic_dict": "ok" if dict_ok else "not_loaded"
        }
    }
