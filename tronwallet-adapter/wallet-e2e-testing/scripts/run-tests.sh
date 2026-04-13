#!/bin/bash
# Run full wallet E2E test suite and generate analysis report
#
# Usage: bash scripts/run-tests.sh [evm|tron|all]
#
set -euo pipefail

cd "$(git rev-parse --show-toplevel)/demos/dev-demo"

TARGET="${1:-all}"

echo "🧪 Running wallet E2E tests (target: $TARGET)..."

case "$TARGET" in
  evm)
    npx playwright test --project=evm-wallet-tests --reporter=list
    ;;
  tron)
    npx playwright test --project=tron-wallet-tests --reporter=list
    ;;
  all)
    npx playwright test --reporter=list
    # Generate JSON report for analysis
    npx playwright test --reporter=json 2>/dev/null > e2e-report/results.json || true
    echo ""
    echo "📊 Generating analysis report..."
    node e2e/analyze-report.mjs
    ;;
  *)
    echo "Usage: $0 [evm|tron|all]"
    exit 1
    ;;
esac

echo ""
echo "✅ Done!"
