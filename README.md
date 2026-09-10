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

## 模块节奏

分模块开发：打磨达标后再 PR 合入 `main`。当前模块见分支命名 `feat/*`。
