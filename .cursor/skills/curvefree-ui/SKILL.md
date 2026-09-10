---
name: curvefree-ui
description: >-
  Design CurveFree UI as a dry strength/nutrition tool. Reference 训记-like
  information architecture and docs/DESIGN.md tokens before writing widgets.
---

# CurveFree UI

## Do first

1. Read `docs/DESIGN.md` tokens.
2. Recall references: tool-first, no social, large numeric entry, near-black gym OLED surfaces, accent `#3DDC97` (not purple kits).
3. Prefer structure from strength apps (训记 / Strong class): list → session → set rows; avoid Keep-style course mall layouts.

## Implement

- Use `AppSpacing` / `AppColors` / `AppStrings` from `lib/core/constants/app_tokens.dart`.
- Home stays brand + training/nutrition entries + local data status only.
- After UI changes, run QA screenshots and visually inspect `tooling/qa/artifacts/*.png`.

## Don't

- Generic purple Material counter demos
- Card spam / community feeds / badge clusters in v-foundation surfaces
