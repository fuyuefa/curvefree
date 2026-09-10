# 质检环

章程路径：

```text
开发 → Docker/本机沙箱 → flutter analyze & test
     → flutter build web + 静态服务
     → Playwright 截图 + Lighthouse
     → 缺陷列表 → 回流修复 → 达标 → PR 合入
```

## Flutter Web 注意

CanvasKit 几乎不把 Flutter 文本暴露到 DOM。`web/index.html` 保留 `#qa-boot` 品牌层供 Playwright 锚定；断言用 `title` / `#qa-boot`，不要对 Canvas 内文字 `getByText`。

## 达标门槛（foundation 起）

| 检查 | 门槛 |
|------|------|
| `flutter analyze` | 无 issue |
| `flutter test` | 全部通过 |
| Playwright | `#qa-boot` 或 Flutter 视图就绪；截图产出 |
| Lighthouse (desktop) | Performance ≥ 0.5，Accessibility ≥ 0.9，Best Practices ≥ 0.8（Web 预览起步值，后续只升不降） |
| 单文件行数 | ≤ 1000 |

可选参数：`node run_qa.mjs --skip-build`（已有 `build/web` 时）。

## 目录

- `docker/` — 沙箱镜像与 compose
- `tooling/qa/` — Node 脚本（Playwright / Lighthouse）
- `tooling/qa/artifacts/` — 截图与报告（gitignore）

缺陷输出：`tooling/qa/artifacts/defects.json`
