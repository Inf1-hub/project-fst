# 逆光

开发记录见 [迭代日志](docs/iteration_log.md)。每次项目修改必须同步更新日志，具体要求见 [项目协作规则](AGENTS.md)。

基于《逆光设计文档》v3.2 的 Godot 2D 战斗 MVP，美术采用已选定的冷灰写实手绘方向。
现已包含白石边境五个同位面小关、人类剑盾、6 种余晖、第五关后位面传送与死亡重试，以及低中高画质。
双击 `run_game.cmd` 即可试玩。完整操作、实现边界和性能验证见 [MVP 说明](docs/mvp.md)。

## 本地启动

- 引擎固定为 Godot **4.7.2 stable** 标准版，精确构建见 `engine.version`。
- 开发语言：GDScript，无需 .NET、Python 包或 Node.js 依赖。
- 本机默认路径：`C:\app\godot\Godot_v4.7.2-stable_win64_console.exe`。
- 在 Godot 项目管理器导入本目录的 `project.godot`，按 F6 运行当前场景或 F5 运行工程。

也可在工程根目录运行 PowerShell：

```powershell
.\tools\godot.ps1 editor
.\tools\godot.ps1 check
.\tools\godot.ps1 run
.\tools\godot.ps1 test
.\tools\godot.ps1 playtest
.\tools\godot.ps1 benchmark
```

如果系统执行策略阻止脚本，可仅对本次进程使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 check
```

其他机器通过 `-GodotPath '完整exe路径'` 或 `GODOT_PATH` 指定同版本引擎。
检查脚本验证精确版本、无界面资源导入和启动，日志存于 `.local/`。
这不替代有窗口的渲染验收、性能测试或 Windows 导出验证。

## 工程布局

按内容域拆目录，不按「Scenes / Scripts / Assets」分桶。`.tscn` 与对应 `.gd` 放在同一文件夹。
目录与文件一律 **snake_case**；GDScript 类名 PascalCase。

| 路径 | 用途 |
| --- | --- |
| `app/bootstrap` | 启动、单局流程与关卡切换（场景 + 脚本同目录） |
| `actors/player`、`actors/monsters` | 玩家与追光者；立绘、动画、场景同夹 |
| `combat/effects` | 正交系统：Damage、Stun、Haste… 只实现规则 |
| `combat/abilities` | 能力容器，只挂 `effects[]`，不为单技能开专属类 |
| `content/ruins` | 十处遗迹手绘零件库 |
| `content/rooms` | L1–L5 房间拓扑，套零件，不预建 52 张整图 |
| `content/afterglow` | 余晖：append / override |
| `data` | CSV 权威数值源（`res://data/`） |
| `ui` | HUD、辉象、菜单 |
| `art`、`audio`、`fonts` | 运行时 2D 资源 |
| `source_assets` | Blender 等源文件；`.gdignore`，不参与导入 |
| `tests` | 后续系统测试 |
| `tools` | 本地开发命令；不参与 Godot 导入 |

默认 Compatibility 渲染；1920×1080 设计分辨率，1280×720 初始窗口，canvas_items 伸缩。
物理更新 60 Hz，帧率上限 60，开启垂直同步。实际性能须待内容接入后测量。
已绑定 WASD、鼠标左右键、Space、Q/E/R/F、C、Tab、Esc，清场领取余晖后通过 Enter 换关；V 暂未接入。
音频总线为 Master、Music、SFX、UI、Ambience。

## 开发边界

遵循设计文档的数据驱动 Ability–Effect 组合；数值进 `data/`，不为单技能写专属类。
场景使用手绘 2D 模块、固定方向平滑跟随 Camera2D 和 Y 排序。MVP 每层五种不规则房间，下一位面复用这五种布局，不预建 52 个关卡文件。
Blender 可用于源素材制作、造型参考或离线渲染；源文件存 `source_assets`，
共用资源放 `art/`，角色和遗迹专用资源与其内容域同目录。不要求 Blender MCP 在线才能启动工程。
CSV 加载和固定容量弹道／特效池已接入；手柄、正式存档、完整导表工具后续开发。

`.godot/`、`.local/`、`build/`、`docs/screenshots/` 以及 `source_assets` 中的方向参考/草稿大图不纳入版本控制；Godot 的 `.uid` 文件应保留。
Windows 发布需要与引擎匹配的导出模板，待发布阶段配置导出预设并验证。
