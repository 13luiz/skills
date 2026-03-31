#!/usr/bin/env bash
# init.sh — Boot dev environment and verify health
set -euo pipefail

echo "=== Environment Recovery ==="

echo "[1/5] Installing dependencies..."
if [ -f "package.json" ]; then
  npm ci --silent
elif [ -f "requirements.txt" ]; then
  pip install -r requirements.txt -q
elif [ -f "pyproject.toml" ]; then
  uv sync -q 2>/dev/null || pip install -e ".[dev]" -q
elif [ -f "go.mod" ]; then
  go mod download
fi

echo "[2/5] Building..."
if [ -f "package.json" ]; then
  npm run build 2>&1 || { echo "BUILD FAILED"; exit 1; }
fi

echo "[3/5] Lint check..."
if [ -f "package.json" ]; then
  npm run lint 2>&1 || echo "LINT WARNINGS"
elif [ -f "pyproject.toml" ] || [ -f "ruff.toml" ]; then
  ruff check . 2>&1 || echo "LINT WARNINGS"
fi

echo "[4/5] Running tests..."
if [ -f "package.json" ]; then
  npm test 2>&1 || { echo "TESTS FAILING"; exit 1; }
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  pytest --tb=short 2>&1 || { echo "TESTS FAILING"; exit 1; }
fi

echo "[5/5] Dev server health..."
if [ -f "package.json" ] && grep -q '"dev"' package.json; then
  npm run dev &
  DEV_PID=$!
  sleep 5
  if curl -sf http://localhost:3000 > /dev/null 2>&1; then
    echo "Dev server healthy"
  else
    echo "WARNING: Dev server may not be responding"
  fi
  kill $DEV_PID 2>/dev/null || true
fi

echo ""
echo "=== Environment Ready ==="
