# 配置约定

依据设计文档 §4.8：玩法数值的权威源是 `res://data/`，代码只实现规则。
MVP 已实现 `game_data.gd` 加载器，技能、余晖、遭遇、画质和基础数值保存在同目录 CSV。

后续按需增加 `formula.csv`、`skill.csv`、`race_trait.csv`、`afterglow.csv`、`resource.csv`、
`floor_curve.csv`、`difficulty.csv`、`monster.csv`、`loot.csv`、`biome.csv`、`status/` 与 `ui/`。
CSV 统一 UTF-8，文件名 snake_case，首行字段名，记录使用稳定且唯一的 ID。
能力采用 effects[] 组合，余晖通过 append / override 修改效果；禁止按单技能派生脚本。
MVP 直接读取 CSV，已经校验基础字段、引用与效果类型；CSV 的 Godot 导入模式为 Keep。
编辑器 Resource 导入和 `user://` 配置覆盖机制留待后续实现。

`rooms.csv` 是当前五关地图的权威配置：outline 为多边形边界，entry/exit 为地面出入口，obstacles 为掩体，spawns/units 一一对应。轮廓同时生成碰撞与寻路；第五关后层级增加并返回第一关。
