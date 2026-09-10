---
name: curvefree-qa
description: >-
  Run CurveFree QA loop: flutter analyze/test, web preview, Playwright
  screenshots, Lighthouse, defects.json feedback. Use when verifying a module,
  before PR, or when fixing QA failures.
---

# CurveFree QA

## When to use

Before merging any module PR, or after UI/storage changes.

## Steps

1. Ensure `C:\flutter\bin` (or local Flutter) is on `PATH`.
2. From repo root: `pwsh tooling/qa/run_qa.ps1` (or `tooling/qa/run_qa.sh`).
3. Docker alternative: `docker compose -f docker/docker-compose.yml run --rm qa` for analyze/test; full Playwright still uses `tooling/qa` on host unless extended.
4. Read `tooling/qa/artifacts/defects.json`.
5. If `ok` is false, fix root causes (not patches), re-run until `ok: true`.
6. Attach screenshot path / Lighthouse summary in the PR body.

## Flutter Web caveats

- Prefer waiting on `document.title` and `flutter-view` / `flt-glass-pane`.
- Do not assert CanvasKit glyph text via Playwright `getByText`.

## Gates

See `docs/QA.md`. Do not lower thresholds silently; document ADR if changing.
