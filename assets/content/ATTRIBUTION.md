# 曲线自由内容包许可

本文件随应用内置，也可在「我的 → 内容包 → 许可与来源」查看

## 程序

曲线自由程序以 GNU GPL-3.0 发布
https://www.gnu.org/licenses/gpl-3.0.html

## 内置动作名

`lib/features/exercises/exercise_catalog.dart` 里的基础动作（id 以 `ex_` 开头）由本项目编写，许可与程序相同：GPL-3.0

应用离线时仍用这份基础目录，内容包只在其上追加或按相同 id 覆盖

## 动作扩展包

`assets/content/exercises.json` 在基础动作之上追加条目

英文名与 `sourceId` 取自 free-exercise-db（The Unlicense，公有领域）
https://github.com/yuhonas/free-exercise-db
https://github.com/yuhonas/free-exercise-db/blob/main/LICENSE.md

中文名是曲线自由自己的译名

没有收录该库的图片，也没有收录动作说明长文（图片许可并不清楚）

动作示意仍用本仓库原创 Lottie，许可 GPL-3.0

## 食物包

`assets/content/foods.json`

`source` 为 `usda` 的每 100 克数值，整理自 USDA FoodData Central 的公开数据（美国政府作品，公有领域）
https://fdc.nal.usda.gov/

行内 `fdcId` 指向来源条目
数值按记录需要做了四舍五入，只供粗记，不是医疗建议

`source` 为 `estimate` 的中餐条目是本项目的粗略估算，许可 GPL-3.0-only，只供记录

Open Food Facts（ODbL）可以作为以后的本地子集来源
v0.1 没有把 OFF 产品库打进安装包
https://world.openfoodfacts.org/
https://opendatacommons.org/licenses/odbl/1-0/

## 字体与动画

见 `docs/CONTENT_ASSETS.md`
