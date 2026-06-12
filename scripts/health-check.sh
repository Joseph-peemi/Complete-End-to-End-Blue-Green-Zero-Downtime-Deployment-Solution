#!/usr/bin/env bash
set -euo pipefail

REQUIRED_CONSECUTIVE=6    # 6 × 10s = 60s of clean responses
POLL_INTERVAL=10
MAX_ATTEMPTS=30           # 5 minutes total before giving up
consecutive=0
attempts=0

echo "Health checking ${DEPLOY_SLOT} slot at http://${ALB_DNS}${HEALTH_PATH}"
echo "Requires ${REQUIRED_CONSECUTIVE} consecutive 200s (${REQUIRED_CONSECUTIVE}×${POLL_INTERVAL}s)"

while [[ $attempts -lt $MAX_ATTEMPTS ]]; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 5 \
    "http://${ALB_DNS}:${HEALTH_PORT}${HEALTH_PATH}" || echo "000")

  if [[ "$HTTP_CODE" == "200" ]]; then
    consecutive=$((consecutive + 1))
    echo "[$(date +%T)] ✓ 200 — consecutive: ${consecutive}/${REQUIRED_CONSECUTIVE}"

    if [[ $consecutive -ge $REQUIRED_CONSECUTIVE ]]; then
      echo "Health check passed — ${DEPLOY_SLOT} is healthy"
      exit 0
    fi
  else
    consecutive=0
    echo "[$(date +%T)] ✗ ${HTTP_CODE} — resetting consecutive counter"
  fi

  attempts=$((attempts + 1))
  sleep $POLL_INTERVAL
done

echo "Health check FAILED after ${MAX_ATTEMPTS} attempts"
exit 1