#!/usr/bin/env bash
# Simulate GitHub Actions CI (test + smoke-oap). Requires Docker.
# Usage: ./scripts/run-ci-github-like.sh [--skip-smoke]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SKIP_SMOKE=0
[[ "${1:-}" == "--skip-smoke" ]] && SKIP_SMOKE=1

command -v docker >/dev/null || {
  echo "Docker required. Or use: dart pub get --no-example && dart analyze && dart test"
  exit 1
}

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

echo "=== [smoke-oap] job ==="
CONTAINER=skywalking-dart-ci-oap
docker rm -f "$CONTAINER" 2>/dev/null || true
docker run -d --name "$CONTAINER" -p 11800:11800 \
  -e SW_STORAGE=h2 -e SW_HEALTH_CHECKER=default \
  apache/skywalking-oap-server:10.2.0

cleanup() {
  docker stop -t 3 "$CONTAINER" 2>/dev/null || true
  docker rm -f "$CONTAINER" 2>/dev/null || true
}
trap cleanup EXIT

for i in $(seq 1 60); do
  if (echo >/dev/tcp/127.0.0.1/11800) 2>/dev/null; then
    echo "OAP gRPC ready after ${i}s"
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "OAP gRPC 11800 not reachable"
    exit 1
  fi
  sleep 2
done

docker run --rm -v "${ROOT}:/app" -w /app \
  -e SW_AGENT_COLLECTOR_BACKEND_SERVICES=127.0.0.1:11800 \
  -e SKYWALKING_SERVICE_NAME=ci-smoke-my-app \
  --network host \
  dart:stable bash -eo pipefail -c '
    dart pub get --no-example
    dart run bin/verify_native.dart --quick
  '

echo "=== GitHub-like CI: all passed ==="
