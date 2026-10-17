# 曲线自由 (CurveFree)

开源、本机优先的力量训练与饮食记录工具。  
训练计划为主，饮食记录为辅；无社区、无商城、无跟练课程、无广告。

## 许可

[GNU GPLv3](LICENSE)

## 技术栈（锁定）

见 [docs/STACK.md](docs/STACK.md)。选定后不随意更换。

## 本地开发

需要：Flutter stable（已验证 3.47+）、Android SDK（真机/模拟器）、Chrome（Web 预览质检）。

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d android
flutter run -d chrome
```

## 质检环

见 [docs/QA.md](docs/QA.md) 与 `tooling/qa/`。

```bash
# Docker 沙箱（本机需 Docker）
docker compose -f docker/docker-compose.yml run --rm qa

# 或本机脚本
./tooling/qa/run_qa.sh   # Git Bash / WSL
# Windows PowerShell:
pwsh tooling/qa/run_qa.ps1
```

## 现在能做什么

- 本机训练课记录（重量/次数/容量）
- 动作库与原创 Lottie 示意循环
- 按目标/天数/器械生成训练计划
- 饮食记录、热量蛋白汇总，以及蛋白缺口建议
- 内容包：内置动作扩展与食物表；可从 GitHub Releases 更新，没网时继续用上一份。见 [docs/CONTENT_PACK.md](docs/CONTENT_PACK.md)

无社区、商城、跟练、云同步。训练和饮食留在本机；可把整库导出成文件，再从文件恢复。

## 模块节奏

分模块开发：打磨达标后再 PR 合入 `main`。当前模块见分支命名 `feat/*`。
