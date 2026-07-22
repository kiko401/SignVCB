#!/bin/bash
set -e

echo "[entrypoint] Checking engine data files..."
/app/scripts/init_data.sh

echo "[entrypoint] Starting uvicorn..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8001 --workers 1
