#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

flutter analyze
flutter test

cd "$ROOT/tooling/qa"
if [[ ! -d node_modules ]]; then
  npm install
  npx playwright install chromium
fi
npm run qa
