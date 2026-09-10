---
name: curvefree-module
description: >-
  Develop one CurveFree feature module end-to-end under the project charter:
  stack lock, local-first storage, modular PR, root-cause fixes. Use when
  starting or finishing a feat/* module.
---

# CurveFree module workflow

## Order of modules

1. foundation / local store (done or extend)
2. training log
3. exercise library + Lottie
4. training plan rules engine
5. nutrition log + open food data
6. later: diet plan assist

## Checklist per module

- [ ] Scope fits charter (no community/mall/courses/cloud sync)
- [ ] Files under `lib/features/<module>/` (+ `core` only if shared)
- [ ] No file > 1000 lines; no unexplained magic literals
- [ ] Tests for domain logic; widget smoke if UI
- [ ] UI checked against tool-app IA (训记-like: dense data, big actions)
- [ ] `flutter analyze` clean; `flutter test` green
- [ ] QA loop green (`curvefree-qa` skill)
- [ ] Branch `feat/<module>` → PR → `gh pr merge` when gates pass

## Forbidden shortcuts

- Swapping Flutter/stack mid-flight
- Patch `if` to hide bugs
- Committing scraped copyrighted food/GIF assets into main
