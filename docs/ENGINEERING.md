# 工程约定

1. 分支：`feat/<module>`、`fix/<topic>`，经 PR 合入 `main`。分支名规则不变。
2. 提交信息：必须遵循 [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)。格式、允许的 type、破坏性变更与正反例见下方「提交信息」。
3. PR：描述含范围、自测方式、质检产物摘要；达标后可用 `gh pr merge`。Squash-merge 的提交标题必须同样遵循 Conventional Commits。
4. 代码风格：`dart format`；`analysis_options.yaml` 为权威。
5. 文件组织：`lib/app` 壳层，`lib/core` 共享，`lib/features/<name>` 功能模块。
6. 注释：只写非显而易见意图；禁止堆砌叙述性废话。

## 文案

用户可见中文文案句末不加「。」。逗号、问号和省略号可以保留。开发注释、许可证和文档不受这条限制。

## 提交信息（Conventional Commits 1.0.0）

每次 commit，以及 PR squash-merge 写进 `main` 的提交标题，都用下面的格式：

```text
<type>(optional-scope): <description>

[optional body]

[optional footer]
```

- **格式**：`<type>(optional-scope): <description>`。scope 可省略；有 scope 时放在圆括号里，例如 `feat(training): …`。冒号后空一格。
- **允许的 type**（只用这些）：`feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`、`revert`。
- **description**：祈使语气、简短，写清做了什么。**英文优先**（行业默认）。
- **body**（可选）：中文或英文均可。原因不明显时说明为什么。
- **破坏性变更**：在 type 或 scope 后加 `!`（如 `feat(storage)!: …`），或在 footer 写 `BREAKING CHANGE: …`。
- **Squash-merge**：合入 `main` 的提交标题必须是同一格式。GitHub 自动追加的 `(#PR)` 可以保留。标题正文使用 Conventional Commits；「第 N 刀」和没有 type 的中文叙述标题不再使用。
- **分支名**仍是 `feat/<module>`、`fix/<topic>`，与提交 type 分开，不因本规则改名。

## 引导

Release 在画像已完成，或本机已有训练、饮食、计划时跳过首次引导。Debug、profile，以及 `--dart-define=FORCE_ONBOARDING=true`，每次进程启动仍进入引导，方便走查；当次完成或跳过后进入今日。组件测试用 `skipOnboarding: true` 直接进壳。

### 合格

本仓库已有历史：

- `feat(training): add local workout log with set keypad`
- `feat(nutrition): log meals from a licensed local food table`
- `feat(exercises): add catalog with original Lottie loops`
- `chore: initialize CurveFree charter, docs, and project skills`

同一变更若按本规范写 squash 标题：

- `feat(training): add rest timer and in-progress float bubble`

### 不合格

近期 squash 标题，此后不再使用：

- `第六刀：组间休息计时与未完成训练浮标 (#12)`
- `第五刀：导出备份与完成、删除训练前先确认 (#11)`
- `视觉 v3.2 第一刀：奶油香芋日夜主题、今日与训练课 (#7)`
