# 内容包 v0.1

曲线自由离线也能记训练和饮食。内容包是叠在内置目录上的动作与食物数据，不是账号，也不同步训练记录。

## 包里有什么

| 文件 | 作用 |
|------|------|
| `assets/content/manifest.json` | 包 id、版本、许可、来源 URL、文件 sha256、GitHub Releases 更新坐标 |
| `assets/content/exercises.json` | 动作扩展。英文名和 `sourceId` 来自 [free-exercise-db](https://github.com/yuhonas/free-exercise-db)（Unlicense）。中文名是本项目译名。不含该库图片和动作说明长文 |
| `assets/content/foods.json` | 食物表。`usda` 行是 USDA FoodData Central 公有领域数值（带 `fdcId`，按记录四舍五入）；`estimate` 行是本项目中餐粗算 |
| `assets/content/ATTRIBUTION.md` | 许可与来源，应用内「我的 → 内容包 → 许可与来源」也可读 |
| `lib/features/exercises/exercise_catalog.dart` | 内置基础动作（`ex_`）。内容包缺失时计划、训练课仍能按这些 id 解析 |

v0.1 没有把 Open Food Facts 产品库打进安装包。ODbL 子集可以作为以后的覆盖包，许可写在 ATTRIBUTION 里。

## 覆盖规则

活动目录 = 内置基础 + 随包扩展 + 本机已安装包。

- 相同 id：后装的替换名称和营养值
- 新 id：追加
- 不删除已有 id。一份不完整的包不会把鸡胸肉或卧推从目录里拿掉
- 训练计划和训练课继续用 `catalogId` / 食物 `foodId` 向活动目录要名字

本机包放在应用支持目录的 `content-pack/` 下，用 `a` / `b` 两个槽和 `active-slot.txt` 指针。校验通过后才改指针。

## 离线

- 没有本机包时用安装包里的基线
- 检查更新时没有网络、校验失败、下载地址不是 GitHub 的 https 资源：不改指针，继续用上一份能通过 sha256 的槽
- 当前槽文件被改坏时，读取会退回另一个仍能校验的槽，再不行就退回内置基线
- Web 预览不能换本地包文件，仍用内置基线

## 用 GitHub Releases 更新

应用只相信**安装包里的** `manifest.json` 写出的仓库（`fuyuefa/curvefree`），不相信已安装包里的更新地址。

1. 读 `https://api.github.com/repos/fuyuefa/curvefree/releases?per_page=10`（新的在前）
2. 找到第一份带资源名 `content-manifest.json` 的 Release
3. 下载该清单，再按清单里的 `file` 下载 `exercises.json` 和 `foods.json`
4. 计算 sha256，必须与清单一致，且格式版本为 `1`
5. 写入空着的那个槽，再次校验，然后把指针换过去

没有带这份资源的 Release（例如只有安装包的版本）会被跳过。

### 发布一份内容包

1. 改 `assets/content/exercises.json` 和/或 `assets/content/foods.json`
2. 把 sha256 写回 `assets/content/manifest.json` 里对应的 `sha256`，并改 `version`

```bash
sha256sum assets/content/exercises.json assets/content/foods.json
```

3. 打一个 GitHub Release（标签名不限），附上三个资源，文件名必须是：

- `content-manifest.json`（内容与 `assets/content/manifest.json` 相同）
- `exercises.json`
- `foods.json`

4. 在应用「我的 → 内容包」点「检查更新」

## 怎么测离线

1. 飞行模式下打开应用：动作库仍有「硬拉」，饮食仍能搜到「鸡胸肉（熟）」
2. 断网点「检查更新」：提示仍用当前内容包，已安装的版本不变
3. 单测 `test/content_pack_test.dart` 覆盖清单解析、ATTRIBUTION、已知 id，以及校验失败时保留上一份
