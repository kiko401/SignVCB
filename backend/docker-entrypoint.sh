#!/bin/bash
set -e

echo "[entrypoint] Waiting for MySQL to be ready..."
until mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" -e "SELECT 1" &>/dev/null; do
    echo "[entrypoint] MySQL not ready, waiting 2s..."
    sleep 2
done
echo "[entrypoint] MySQL is ready."

echo "[entrypoint] Running database migrations..."
cd /app
alembic upgrade head

echo "[entrypoint] Seeding initial data..."
python -m app.scripts.seed_local

echo "[entrypoint] Starting uvicorn..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
