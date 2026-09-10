# 工程约定

1. 分支：`feat/<module>`、`fix/<topic>`，经 PR 合入 `main`。
2. 提交信息：中文或英文均可，说明「为什么」；一个逻辑变更一次提交亦可多次，模块结束前整理清楚。
3. PR：描述含范围、自测方式、质检产物摘要；达标后可用 `gh pr merge`。
4. 代码风格：`dart format`；`analysis_options.yaml` 为权威。
5. 文件组织：`lib/app` 壳层，`lib/core` 共享，`lib/features/<name>` 功能模块。
6. 注释：只写非显而易见意图；禁止堆砌叙述性废话。
