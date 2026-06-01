#!/usr/bin/env bash
# Simulate GitHub Actions CI (keep in sync with .github/workflows/ci.yml).
# Usage: ./scripts/run-ci-github-like.sh [--skip-smoke]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OAP_IMAGE="${OAP_DOCKER_IMAGE:-apache/skywalking-oap-server:10.1.0}"
OAP_CONTAINER=ci-oap
cd "$ROOT"
SKIP_SMOKE=0
[[ "${1:-}" == "--skip-smoke" ]] && SKIP_SMOKE=1

command -v docker >/dev/null || { echo "Docker required"; exit 1; }
command -v dart >/dev/null || { echo "dart required for smoke compile"; exit 1; }

echo "=== [test] job (dart:stable) ==="
docker run --rm -v "${ROOT}:/app" -w /app dart:stable bash -eo pipefail -c '
  dart pub get --no-example
  dart analyze lib bin test
  dart test
'

if [[ "$SKIP_SMOKE" -eq 1 ]]; then
  echo "Skipped smoke-oap"
  exit 0
fi

echo "=== [smoke-oap] job (OAP on host + dart run verify) ==="
if ! docker image inspect "$OAP_IMAGE" >/dev/null 2>&1; then
  echo "Pulling $OAP_IMAGE ..."
  docker pull "$OAP_IMAGE" || { echo "Cannot pull OAP image"; exit 1; }
fi
docker rm -f "$OAP_CONTAINER" 2>/dev/null || true
docker run -d --name "$OAP_CONTAINER" -p 11800:11800 \
  -e SW_HEALTH_CHECKER=default \
  "$OAP_IMAGE"

cleanup() { docker rm -f "$OAP_CONTAINER" 2>/dev/null || true; }
trap cleanup EXIT

for i in $(seq 1 90); do
  if (echo >/dev/tcp/127.0.0.1/11800) 2>/dev/null; then
    echo "OAP TCP 11800 open after ${i} attempts; warm-up 20s..."
    sleep 20
    break
  fi
  if [[ "$i" -eq 90 ]]; then
    docker logs "$OAP_CONTAINER" || true
    echo "OAP gRPC 11800 not reachable"
    exit 1
  fi
  sleep 2
done

dart pub get --no-example

export SW_AGENT_COLLECTOR_BACKEND_SERVICES=127.0.0.1:11800
export SKYWALKING_SERVICE_NAME=ci-smoke-my-app
for attempt in 1 2; do
  echo "verify_native attempt $attempt/2"
  if timeout 60 dart run bin/verify_native.dart --quick; then
    echo "=== [smoke-oap] passed ==="
    exit 0
  fi
  if [[ "$attempt" -lt 2 ]]; then
    echo "retry in 10s..."
    sleep 10
  fi
done

docker logs "$OAP_CONTAINER" || true
echo "=== [smoke-oap] FAILED ==="
exit 1
