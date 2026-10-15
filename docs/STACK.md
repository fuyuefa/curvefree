# 技术栈锁定

变更栈需单独 ADR + 维护者确认，禁止随手替换。

| 层 | 选型 | 说明 |
|----|------|------|
| 客户端 | Flutter stable | Android 为主交付；iOS 后置 |
| Web | Flutter Web | **仅预览与质检**，非产品主入口 |
| 状态 | flutter_riverpod | 显式依赖注入与测试友好 |
| 本机存储 | JSON 文档库（path_provider / SharedPreferences） | 无云同步；写入串行并先写临时文件再替换 |
| 备份文件 | file_picker + share_plus | 用户主动另存/分享 JSON；应用不上传训练或饮食 |
| 动作动画 | Lottie | 本仓库原创几何循环，见 `docs/CONTENT_ASSETS.md` |
| 食物营养 | `assets/data/foods.json` | USDA 公有领域典型值 + 中餐近似估算，见文件 attribution |
| 许可 | GPL-3.0 | 允许使用但衍生分发需保持开源 |
| 质检 | flutter analyze/test + Playwright + Lighthouse | Web 预览路径 |

## 工程纪律

- 单文件不超过 **1000** 行
- 禁止无说明的魔法数字/魔法字符串（抽到 `core/constants` 或具名常量）
- 修缺陷查根因，禁止补丁式临时顶住
- 模块达标后再提交并开 PR
