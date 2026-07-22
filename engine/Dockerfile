FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ libgomp1 curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/
COPY scripts/ ./scripts/
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

RUN mkdir -p /app/models /app/data /data/logs && \
    chmod +x /app/docker-entrypoint.sh /app/scripts/init_data.sh && \
    sed -i 's/\r$//' /app/docker-entrypoint.sh /app/scripts/init_data.sh

ENV OMP_NUM_THREADS=2
ENV TORCH_NUM_THREADS=2

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

EXPOSE 8001

ENTRYPOINT ["/app/docker-entrypoint.sh"]
