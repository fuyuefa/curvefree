---
name: curvefree-ui
description: >-
  Design CurveFree UI as a dry strength/nutrition tool. Reference 训记-like
  information architecture and docs/DESIGN.md tokens before writing widgets.
---

# CurveFree UI

## Do first

1. Read `docs/DESIGN.md` and `lib/core/constants/curve_palette.dart` (visual v3.2 奶油香芋).
2. Recall references: tool-first, no social, large numeric entry. Surfaces are cream / warm night, primary is taro `#9B7EBD` / `#B8A0D4`, accent is soft peach, completed sets are sage. Do not use pure white, pure black, neon purple, or the retired gym green `#3DDC97`.
3. Prefer structure from strength apps (训记 / Strong class): today → session → set rows; bottom nav is 今日 / 训练 / 饮食 / 我的. Avoid course-mall layouts.

## Implement

- Use `AppSpacing` / `AppRadii` / `AppStrings` from `lib/core/constants/app_tokens.dart`.
- Read colors from `CurveColors.of(context)`, which comes from `buildCurveFreeTheme`.
- Today shows resume, week progress, muscle dots, and the plan entry. Local backup stays on 我的.
- After UI changes, run QA screenshots and visually inspect `tooling/qa/artifacts/*.png`.

## Don't

- Neon purple kits or pure black gym surfaces
- Card spam / community feeds / badge clusters in v-foundation surfaces
