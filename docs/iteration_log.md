# 逆光 · 迭代日志

本日志记录目标、实际改动、验证与遗留问题。编号用于追踪迭代，不代表发布版本。

ITER-001～ITER-006 于 **2026-09-11 补录**，依据本任务历史、现有文件及本地测试日志整理；具体实施日期未逐次确认，不反推日期。历史测试只说明当时状态，不代表当前版本必然通过。`.local/` 中的日志可能被后续运行覆盖。

## ITER-014 · 场景地图优化：关卡辨识度

- **日期**：2026-09-11
- **状态**：已实现并自查（第一、二步完成，五关视觉已明显区分）；后续可继续光照/地表分层/死代码清理。
- **目标/原因**：五关（破营侧道/折院迂回/断墙长廊/废营纵深/主将前庭）视觉几乎一致，缺乏辨识度。建立"每关主题"的数据驱动基础，从地表/地形色调差异化 + 点缀色地标入手。
- **实际改动**：
  - 第一步（地表/地形按主题差异）：
    - 新增 `data/room_themes.csv`：按房间 id 定义 `base_tint/stone_mix/earth_low/earth_high/prop_tint/accent`（冷灰统一基调下的温度/明度/色相差异）。
    - `data/game_data.gd`：加载 `room_themes` 到 `themes`，`validate()` 断言每关都有主题。
    - `content/rooms/ground_tone.gdshader`、`terrain_fill.gdshader`：参数化色调（`base_tint/stone_mix`、`earth_low/earth_high`），默认值保持原观感。
    - `content/rooms/border_room.gd`：新增 `theme` 与取色辅助（`theme_vec3`/`theme_color`），`configure` 写入地面材质、`add_terrain_mass` 写入地形材质。
    - `app/bootstrap/bootstrap.gd`：`load_floor` 按关卡 id 取主题赋给 `room.theme` 再 `configure`。
  - 第二步（布景/掩体着色 + 点缀色地标）：
    - `content/ruins/scenery_prop.gd`、`ruin_piece.gd`、`cover_cluster.gd`：新增 `tint`，把边界布景与掩体石材按主题 `prop_tint` 上色（默认值等同原观感）。
    - 新增 `content/ruins/accent_banner.gd`：带落地阴影的主题战旗地标。
    - `app/bootstrap/bootstrap.gd`：掩体/布景按 `prop_tint` 上色；在每关战术锚点（`zones`）放置 `accent` 色战旗作为焦点地标。
- **关键文件**：`data/room_themes.csv`、`data/game_data.gd`、`content/rooms/ground_tone.gdshader`、`content/rooms/terrain_fill.gdshader`、`content/rooms/border_room.gd`、`content/ruins/scenery_prop.gd`、`content/ruins/ruin_piece.gd`、`content/ruins/cover_cluster.gd`、`content/ruins/accent_banner.gd`、`app/bootstrap/bootstrap.gd`。
- **验证结果**：
  - 冒烟无脚本/着色器错误；`tools/godot.sh test` 五套全部 `0 failures`（含新增主题断言）。
  - 经 `xvfb-run` 渲染五关截图逐张自查：五关地表基调明显拉开（L1 暖灰、L2 冷蓝灰、L3 中性尘灰、L4 橄榄暗绿、L5 冷钢蓝且最暗）；战旗点缀色按关变化（L1 锈红、L2 苔绿、L4 橄榄黄、L5 主将前庭猩红），战旗带落地阴影；角色与掩体可读性保持。
  - 修复过程：`var anchor := room.nearest_walkable(...)` 因目标函数未标注类型导致解析失败，改为显式 `var anchor: Vector2`。
- **遗留问题/下一步**：辨识度已显著改善但仍可深化——建议后续加入 `CanvasModulate`/廉价方向光与更多落地阴影（体量感）、地表分层遮罩（路径/血迹引导视线）、掩体构型与密度按关差异，以及清理 `perimeter_wall`/`wall_module`/`distant_landscape` 死视觉代码（需同步 `terrain_contract_test` 与 `docs/mvp.md`）。战旗为非碰撞装饰，未改动战斗数值与几何。

## ITER-013 · Cloud Agent（Linux）开发环境搭建与实机验证

- **日期**：2026-09-11
- **状态**：已完成并本地验证；环境保存（Save）为用户侧动作，待用户在环境面板确认。
- **目标/原因**：原工程仅提供 Windows 引擎路径与 `tools/godot.ps1`，Cloud Agent 运行于 Linux（Ubuntu 24.04 x86_64）。需要在无预置引擎的 Linux VM 上一键准备同版本 Godot 并运行工程，证明环境可用。
- **实际改动**：
  - 新增 `.cursor/environment.json`：使用 Cursor 默认镜像，`install` 执行 `bash .cursor/install.sh`。
  - 新增 `.cursor/install.sh`：按 `engine.version` 解析并下载官方 `Godot_v4.7.2-stable_linux.x86_64` 到 `~/.local/share/godot/godot`，校验 `--version` 精确匹配 `4.7.2.stable.official.ed1daf0bf`，软链到 `~/.local/bin/godot`，随后无界面导入资源。幂等：已匹配则跳过下载；仅在缺少 `xvfb-run/unzip/curl/libGL` 时才 `apt` 补装。
  - 新增 `tools/godot.sh`：Linux 版开发脚本，任务与 `tools/godot.ps1` 对齐（editor/run/check/test/playtest/benchmark）；有窗口任务在无 `DISPLAY` 时经 `xvfb-run` 软件渲染（Mesa llvmpipe）。
  - 未改动任何游戏代码、数值或资源；`tools/godot.ps1` 与 Windows 流程保持不变。
- **关键文件**：`.cursor/environment.json`、`.cursor/install.sh`、`tools/godot.sh`、`docs/iteration_log.md`。
- **验证结果**（本机 Cloud VM，Ubuntu 24.04 x86_64，Godot 4.7.2.stable.official.ed1daf0bf）：
  - 引擎版本精确匹配；`--headless --import` 资源导入通过。
  - `tools/godot.sh check`：PASS（引擎版本、导入、启动）。
  - `tools/godot.sh test`：全部通过——`TERRAIN CONTRACT: 0 failures`、`TACTICAL TEST: 0 failures`、`CAMERA TEST: 0 failures`、`ROOM FLOW: 0 failures`、`MVP TESTS: 0 failures`。
  - `benchmark`（无界面、28 敌、低/中/高）：mean ≈ 6.90/6.90/6.90 ms，p95 ≈ 7.91/8.06/8.07 ms，静态内存 ≈ 73.8 MB（软件渲染 llvmpipe，`draw_calls` 报 0，仅代表本机该场景，非渲染性能规律）。
  - 有窗口渲染：经 `xvfb-run` 用 `tests/visual_capture.gd` 生成标题、五关、走廊、远射阵地等截图，画面正常；另用临时录制脚本驱动真实输入录制约 15 秒战斗片段并核验（角色移动、近战特效、清场后移动、HUD 与小地图正常，无渲染异常）。临时录制脚本 `tests/_demo_capture.gd` 已删除，不纳入提交。
  - `install.sh` 幂等：本机首次全新安装约 3 分钟（含 apt 与下载）；已就绪后重复运行约 2.5 秒，跳过下载与 apt。默认镜像已含依赖时无需 apt。
  - 云端构建验证：以本分支触发草稿构建 `bld-20260911-7d3226cc-a1e8-4171-9b93-316b5bc3da8a`，`install.sh` 在全新 pod 上下载并导入成功，Exit 0，构建 **SUCCEEDED**（默认镜像已具依赖，未跑 apt，安装段约 9 秒）。
  - 全新云端代理从该构建启动复核 4 项全部通过：引擎版本精确匹配、`.godot` 导入缓存存在、`tools/godot.sh check`+`test` 全绿、`xvfb-run` 渲染出非空截图。
- **交付方式**：环境以**仓库内 `.cursor/environment.json`（repo-managed，最高优先级）**交付，随 PR 合并即对该分支生效，无需在环境面板 Save。草稿构建源自非默认分支，仅用于验证、不可提升为 active；合并到默认分支后如需预构建快照可再触发可提升构建。
- **遗留问题/下一步**：
  - `tools/godot.sh playtest`（自动通关）本次仍**失败**：种子 `131833513`，击杀 41 名敌人后第 29900 帧死亡。此为 ITER-006 记录的历史游戏平衡问题，非环境问题（引擎、导入、其余测试均正常），本次不在环境搭建范围内修复。
  - 音频在无声卡 VM 回退为 dummy 驱动（ALSA 无 card），属预期，不影响逻辑与渲染。

## ITER-012 · 初始化 Git 并推送到 GitHub

- **日期**：2026-09-11
- **状态**：已完成
- **目标/原因**：将工程推送到空仓库 https://github.com/Inf1-hub/project-fst，并排除不适合上传的非关键大资源。
- **实际改动**：补全 `.gitignore`：继续忽略 Godot 缓存、本机日志与导出产物；新增忽略可再生成的验证截图、源稿/方向参考大图、常见离线源文件与系统杂项。运行时贴图、脚本、CSV、`.uid` 与 `source_assets` 清单 JSON 仍纳入版本控制。初始化本地 Git，远程为 `origin`，已推送 `main`。
- **关键文件**：`.gitignore`、`README.md`、`docs/iteration_log.md`
- **验证结果**：未执行游戏测试（本次只改版本控制与文档）。`git check-ignore` 已确认 `.godot/`、`.local/`、`docs/screenshots/`、`source_assets/art_drafts/` 与 `source_assets/art_direction_a.png` 被忽略；运行时 PNG、`.uid`、CSV 与 `source_assets` JSON 清单已纳入版本控制，约 147 个文件 / 30.6 MB。`git push -u origin main` 成功，`main` 跟踪 `origin/main`。
- **遗留问题/下一步**：无。验证截图与源稿大图仅保留在本机，克隆仓库后需本地重新截图或自行拷贝。

## ITER-011 · 弯曲边界与不可通行区环境填充

- **日期**：2026-09-11
- **状态**：已实现，本次回归和实机检查完成。
- **目标/原因**：连续细长投影墙在俯视角下失真，通道过于规整，不可通行区大片空白。替换 ITER-010 的外围墙渲染方式。
- **实际改动**：
  - 主线与分支通道加入弯曲中心线、变化宽度和圆钝肩部，重新生成五关轮廓、碰撞边、不可通行区三角面及寻路格。保留左向右、三交火区、侧翼路线与五关进程。
  - 删除外围投影墙生成及实例化，以不旋转的低岩台、荆棘衔接边界。不可通行区内部加入大型岩丘、废弃礼拜堂、残楼、枯树与藤蔓灌木；大组件放置前检查投影包围范围的采样点，限制侵入通路。
  - 使用内置 image_gen 生成真实透明六组件图集，提示词和资源规范保存在 `docs/scenery_assets.md`。图集共享，原比例绘制、Y 排序、固定种子布局、开启 mipmaps。
  - 将地图生成器保存到 `tools/build_tactical_rooms.py`（Python + Shapely），更新 CSV 与拓扑图；测试改为检查六种布景均存在、落地点位于不可通行区，且不再实例化旧墙体。
- **关键文件**：`data/rooms.csv`、`tools/build_tactical_rooms.py`、`app/bootstrap/bootstrap.gd`、`content/rooms/border_room.gd`、`content/ruins/scenery_prop.gd`、`content/ruins/scenery_atlas_v1.png`、`tests/terrain_contract_test.gd`、`tests/visual_capture.gd`、`docs/screenshots/scenery_corridor.png`、`docs/scenery_benchmark.json`。
- **验证结果**：`tools/godot.ps1 check` 和 `test` 全部通过，五关各 354/363/358/359/368 个场景组件，均覆盖六类。边缘初版跳过短边导致空档，改为沿闭合轮廓累计距离布置，随后复测并检查走廊、庭院截图。图集读取确认存在透明像素；最终实机截图、性能日志无绘制报错。
  - 本机 RTX 4060 Laptop、1080p、28 敌人压力场景：低/中/高平均 2.089/2.080/2.981 ms，P95 3.333/3.355/4.671 ms，静态内存约 80.5 MB。低中轻微倒挂属于此次采样结果，不推断为画质性能规律。
- **遗留问题/下一步**：布局仍为同一主骨架的五种配置，局部岩台重复可继续美术细化；大组件范围检查为采样检查，并非逐像素遮挡保证。新建筑是环境布景，不能进入。旧完整战斗通关失败未在本次修复或重新验收。

## ITER-010 · 外围地形墙立体化

- **日期**：2026-09-11
- **状态**：实现完成，回归与实机渲染检查通过。
- **目标/原因**：外围不可通行区仍像地面描边，没有墙顶、立面和墙脚，纠正 ITER-008 的边带方案。
- **实际改动**：删除 Line2D 边带，沿原碰撞轮廓建立具有墙顶、内外立面的投影墙体；厚度向不可通行侧延伸，拐角使用共享接点并限制尖角外扩。墙高连续变化，突出转角加入墙墩，局部墙顶及墙脚加入碎石。各墙段按落地点参与角色 Y 排序；墙后区域使用独立土石色材质，区分可走地面。使用现有纹理，没有新增大贴图或逐帧生成地形。
- **关键文件**：`content/ruins/perimeter_wall.gd`、`content/rooms/border_room.gd`、`content/rooms/terrain_fill.gdshader`、`app/bootstrap/bootstrap.gd`、`tests/terrain_contract_test.gd`、`docs/screenshots/perimeter_volume.png`、`docs/perimeter_benchmark.json`。
- **验证结果**：
  - 首次测试发现竖直投影的零面积面导致 triangulation failed；改为显式三角面并跳过零面积面，复测通过。首次截图的面纹理比例过密，随后修正。
  - `tools/godot.ps1 test` 全部通过：五关分别 320/340/307/328/344 墙段；绘制接触边总长与物理边界一致，共享接点的厚度边和高度一致；地形、战术、相机、流程、MVP 均为 0 failures。
  - 最后仅调整立面投影与墙后材质，重新执行五关实机截图和三档压力测试，日志无 ERROR；第三关截图已检查并保存。
  - 最终 `tools/godot.ps1 benchmark`：RTX 4060 Laptop、1080p、28 敌人、不限帧；低/中/高平均 1.928/2.515/3.219 ms，P95 为 2.963/3.978/4.738 ms，静态内存约 80.5 MB。相比 ITER-009 增加墙体带来额外绘制开销，报告保留实际结果。
- **遗留问题/下一步**：这是现有 2D 工程中的投影墙体，局部石材重复和长直段仍可进一步美术细化；不等于 POE2 的完整环境美术品质。当前依靠 Y 排序，未实现前景遮挡自动淡出。整局战斗通关历史失败仍未在本次处理。

## ITER-009 · 废墟障碍重做：断口与错位堆积

- **日期**：2026-09-11
- **状态**：已实现并通过本次回归；美术仍使用现有模块资源。
- **目标/原因**：纠正 ITER-008 为对齐碰撞而改成规则石砖块的处理。中途恢复贴图但继续行列堆砌的版本也被用户否定，不作为验收版本。
- **实际改动**：删除按行列填满矩形的逻辑，改为断裂墙端、偏移坍塌块与中央通路的非均匀组合。复用原断墙的不同透明区域，保留破损顶部和立面；碎石按原比例绘制，不再纵向拉长。各残块以落地位置参与 Y 排序。
  - 原配置矩形只保留为组合放置范围；每关生成 21 个八边形简化落地轮廓，替换矩形物理碰撞。
  - 观察阻挡、移动判断、小地图改用残块轮廓；重算旧放置范围周边寻路格，释放断口，避免保留不可见矩形阻挡。
  - 更新地形测试，验证落地形状与物理形状一致、中心阻挡、断口可通行和视线可穿过、寻路格与人物安全距离一致。
- **关键文件**：`content/ruins/cover_cluster.gd`、`content/ruins/ruin_piece.gd`、`content/rooms/border_room.gd`、`app/bootstrap/bootstrap.gd`、`ui/tactical_map.gd`、`tests/terrain_contract_test.gd`、`docs/screenshots/ruins_composition.png`、`docs/ruins_benchmark.json`。
- **验证结果**：
  - 导入与启动检查通过；最终 `tools/godot.ps1 test` 的地形、战术、相机、五关流程、MVP 均为 0 failures。五关共 105 个残块碰撞，无矩形障碍碰撞；35 处组合中心断口通过走位与视线检查。
  - Godot `--fixed-fps 60 --script res://tests/visual_capture.gd --quit-after 1600` 实机截图已检查并保存。首张检查发现碎石拉伸，修正后重新截图。
  - `tools/godot.ps1 benchmark`：RTX 4060 Laptop，1920×1080，28 敌人，无帧率上限；低/中/高平均 1.235/1.830/2.660 ms，P95 为 2.133/3.084/3.873 ms，静态内存约 77 MB。结果仅代表该固定压力场景及本机，非整局最低帧率保证。
- **遗留问题/下一步**：当前是三种比例组合，复用现有断墙及碎石，尚未制作整组独立绘制的美术资源；轮廓是简化落地占地，不是逐像素碰撞。旧 CSV 矩形目前用作摆放范围。未重跑整局自动战斗通关，ITER-006 的历史失败仍待单独处理。

## ITER-008 · 地形可见占地、深色块与边缘接缝修复

- **日期**：2026-09-11
- **状态**：功能修复与回归完成；美术细节仍可继续打磨。
- **目标/原因**：障碍物贴图与碰撞不一致，深色覆盖像矩形假阴影，旋转碎石逐段拼接导致拐角杂乱。
- **实际改动**：障碍物改为复用现有石墙纹理的低矮石砌体，底座按原碰撞矩形完整绘制，正面收在占地内部；取消拉伸碎石与木栅叠图。边缘取消旋转碎石和按边索引堆放的装饰，改为直接使用物理轮廓的闭合圆角石质边带。不可通行区改为连续世界坐标纹理，移除原来浓重的半透明深色覆盖；这部分是地形区分，不是真实投影。截图脚本使用强制渲染避免等待后台窗口绘制事件。
- **关键文件**：`content/ruins/cover_cluster.gd`、`content/rooms/border_room.gd`、`app/bootstrap/bootstrap.gd`、`tests/terrain_contract_test.gd`、`tests/visual_capture.gd`、`tools/godot.ps1`、`docs/screenshots/terrain_alignment.png`。
- **验证结果**：
  - 首次沙箱内 `tools/godot.ps1 check` 因便携版 Godot 无法写入 C:/app/godot/editor_data 与读取证书失败；经工具审批后重跑导入、启动通过。
  - 最终 `tools/godot.ps1 test` 全部通过：五关共 35 个可见底座与实际矩形碰撞一致，15 条边带闭合且点集来自物理边界；战术布局、相机、五关流程、基础 MVP 测试均为 0 failures。
  - 使用 Godot `--fixed-fps 60 --script res://tests/visual_capture.gd --quit-after 1600` 生成截图，并检查第三关中转区最终渲染；截图保存为 `docs/screenshots/terrain_alignment.png`。
- **遗留问题/下一步**：低矮石砌体目前偏规整，需要后续在不改变可见占地的前提下细化破损与材质变化。边带宽 28 单位，碰撞线位于中央；其两侧各 14 单位为视觉过渡。未重跑整局战斗通关与三档性能压力测试，ITER-006 的通关失败仍未在本次解决。

## ITER-007 · 建立迭代记录制度

- **日期**：2026-09-11
- **状态**：已完成（文档）
- **目标/原因**：多轮修改缺少统一追踪，明确要求以后每次迭代都写日志。
- **实际改动**：补录六个历史阶段；在根目录增加全仓库适用的日志规则，规定必填项、更新时机、失败与中断记录方式；在 README 增加入口。
- **关键文件**：`AGENTS.md`、`docs/iteration_log.md`、`README.md`。
- **验证结果**：核对现有源码、设计文档版本和最近测试日志；检查日志条目、规则与入口链接。本次只修改文档，未运行游戏测试。
- **遗留问题/下一步**：ITER-006 的远射阵地复测仍待继续。本次建立日志不代表该问题已修复。

## ITER-006 · 左向右推进与战术地形

- **记录方式**：2026-09-11 历史补录
- **状态**：已实现，验证未完成
- **目标/原因**：解决场地空旷、只有零散障碍、路线短且地形缺少战术作用的问题。
- **实际改动**：
  - 五关改为左侧入口、右侧出口，串联近距交火区、中转通道和远射阵地；增加上下折返及两条可重新汇入的侧翼路线。
  - 使用不规则外轮廓与内部不可通行区域；轮廓、碰撞、寻路和地面遮罩按配置生成。
  - 支路加入一次性回复补给；遮蔽棚支持向右窥视、从外侧难以发现内部目标、近距离暴露。遮蔽影响观察，不提供单向弹道免疫。
  - 敌人发现目标需经过观察判断，丢失视野后保留短时记忆；弓手使用远射范围与驻守约束。
  - 生成直接读取配置和实际寻路结果的拓扑图，增加战术规则测试。
- **关键文件**：`data/rooms.csv`、`data/mvp_settings.csv`、`content/rooms/border_room.gd`、`actors/combat_actor.gd`、`app/bootstrap/bootstrap.gd`、`ui/tactical_map.gd`、`tests/tactical_layout_test.gd`、`docs/screenshots/tactical_layout.png`。
- **验证结果**：
  - `tools/godot.ps1 check`：当时导入与启动通过。
  - 最近 `tools/godot.ps1 test`：战术布局、相机、五关流程、基础 MVP 测试通过。
  - 战术测试验证：封住主通道仍可经支路通行、补给可达且仅领取一次、单向观察与近距离暴露、敌人失去隐藏目标。
  - 最终配置的最短路线约 **8,356～8,894** 世界单位；按普通移动速度估算 **31.5～33.6 秒/关**，不含战斗、绕路探索或冲刺。
  - 较早的正常输入通关曾通过，用时约 391.8 秒；后续修改后的最近一次 `playtest` **失败**：种子 `1447237858`，击杀 5 名敌人后于第 4542 帧死亡。不能据早先通过宣称当前版本已完整验收。
  - 曾运行本机 RTX 4060 Laptop、1080p、28 敌人的三档压力测试；这些属于阶段性结果，最终拓扑微调后未完成新的完整性能验收。
- **遗留问题/下一步**：
  - 原测试脚本未充分应对远射弹道；计划补充真实举盾挡箭与冲刺输入，再使用失败种子复测，并判断是否还需平衡调整。
  - 上述脚本修改与复测命令在创建进程前被自动审批拒绝，原因是使用额度耗尽，**该命令未执行，修改未落地**。继续前先检查文件，不能假定已修复。
  - 部分 README/MVP 说明仍保留旧地图名称、规模与敌人数，需要与当前配置同步。
  - `逆光地图生成设计.md` 当前为 v1.1；其存在不表示完整随机生成、失败重生成、高程等要求已经实现。当前仍是配置化的五关原型。

## ITER-005 · 镜头比例与房间内部布局

- **记录方式**：2026-09-11 历史补录
- **状态**：阶段完成，地图布局后来由 ITER-006 继续重做
- **目标/原因**：整间房一屏看完、角色过小，扩大地图仍缺少内部结构。
- **实际改动**：相机缩放由 0.8 调为 1.2，取消房间中心固定位置，增加平滑跟随与拖拽死区；扩大布局、加入成组掩体，按小队激活敌人；寻路与战术地图适配房间范围。
- **关键文件**：`app/bootstrap/bootstrap.gd`、`data/rooms.csv`、`data/mvp_settings.csv`、`content/ruins/cover_cluster.gd`、`tests/camera_test.gd`。
- **验证结果**：当时相机测试确认可见范围约 1600×900、镜头实际跟随移动且角色仍在视野内；功能及正常输入五关通关通过。查到《哈迪斯 2》官方演示入口，但参考截图读取连续超时，未完成逐帧对照。
- **遗留问题/下一步**：用户反馈仍主要是放大地图、缺少真正的空间与战术关系，转入 ITER-006；不可将参数称为原作精确复刻。

## ITER-004 · 五关同位面流程与统一地面

- **记录方式**：2026-09-11 历史补录
- **状态**：阶段完成
- **目标/原因**：纠正把“向上爬层”表现为悬空地形的理解，解决远景与战斗场景割裂。
- **实际改动**：每个位面包含五个连续小关；前四关换关，第五关后传送下一位面第一关并保留构筑。移除天空远景与悬空城垣，采用连续地面、不规则边界、碎石、木栅与营地；清场领取余晖后才允许换关。
- **关键文件**：`data/rooms.csv`、`content/rooms/border_room.gd`、`app/bootstrap/bootstrap.gd`、`content/ruins/*_v3.png`、`tests/room_flow_test.gd`。
- **验证结果**：当时五关推进、构筑保留、出口和敌人连通性、冲刺边界碰撞与正常输入通关通过；检查了透明贴图与三档性能。修复了转角寻路卡住的问题。
- **遗留问题/下一步**：固定中心镜头使房间像全景展示板；边界和内部掩体仍有明显重复，进入 ITER-005。

## ITER-003 · 冷灰写实手绘美术接入

- **记录方式**：2026-09-11 历史补录
- **状态**：阶段完成，场景方案后来调整
- **目标/原因**：用户选择第一张参考图：沉静、厚重的冷灰中古战场。
- **实际改动**：接入碎石地、城门、城垣、暗红旗帜与远景；补充玩家背面和独立主将造型；限制贴图导入尺寸，启用 mipmap。素材通过内置 image_gen 生成并保存到项目，未将 Blender MCP 设为运行依赖。
- **关键文件**：`content/ruins/`、`actors/player/knight_back_v2.png`、`actors/monsters/captain_v2.png`、`source_assets/art_manifest.json`、`source_assets/art_revision_v2.json`。
- **验证结果**：当时资源导入、透明通道检查、功能测试与实际渲染通过。生成中出现过烘焙棋盘格背景的失败素材，未作为最终透明贴图使用。
- **遗留问题/下一步**：用户指出远景与战斗平面割裂、呈现悬空感，因此 ITER-004 移除了该场景组合。角色仍缺完整多方向逐帧/骨骼动画。

## ITER-002 · 可玩战斗 MVP

- **记录方式**：2026-09-11 历史补录
- **状态**：阶段完成
- **目标/原因**：实现一个职业、部分余晖及进入战场到下一关的完整循环，同时控制性能。
- **实际改动**：人类剑盾移动、攻击、格挡/精确格挡、冲刺与技能；Ability–Effect 数据组合；六种余晖与三选一；步兵、弓手、号手、主将；掉落、过关、死亡重试、HUD、战术地图、合成音效和低中高画质。弹道与特效采用固定容量池，AI 分频决策。
- **关键文件**：`actors/`、`combat/`、`data/`、`ui/`、`audio/`、`tests/mvp_test.gd`、`tests/playthrough_test.gd`、`tests/stress_test.gd`。
- **验证结果**：当时 23 项基础集成检查通过；正常输入完成原版单关到下一层；进行 RTX 4060 Laptop 压力测试。初版为三组守军加主将共 14 敌人，与当前配置不同。
- **遗留问题/下一步**：地图稀疏、美术处于原型阶段；未交付独立 Windows 安装包、正式存档、完整动画和录制音效。

## ITER-001 · 开发环境与工程标准

- **记录方式**：2026-09-11 历史补录
- **状态**：阶段完成
- **目标/原因**：先初始化开发环境，再按照用户更新的项目标准开发。
- **实际改动**：固定 Godot 4.7.2 构建；建立 2D GDScript 工程、启动入口、本地开发脚本和一键运行入口。采用内容域目录、snake_case、场景与脚本同目录、`data/` CSV 权威配置，遵循设计文档 v3.2。
- **关键文件**：`project.godot`、`engine.version`、`app/bootstrap/`、`tools/godot.ps1`、`run_game.cmd`、`README.md`。
- **验证结果**：当时确认本机 `C:\app\godot` 的指定引擎可执行版本、资源导入和启动；Blender MCP 可作为可选资源制作工具，游戏不依赖其在线。
- **遗留问题/下一步**：开始 MVP 内容实现；Windows 正式导出仍需匹配版本的导出模板。

---

## 新迭代模板

复制到日志顶部，替换编号与内容。状态可使用“进行中”“已完成”“已实现，验证未完成”“受阻”，并说明具体原因。

```markdown
## ITER-XXX · 本次迭代标题

- **日期**：YYYY-MM-DD（跨日则记录范围；补录须注明）
- **状态**：
- **目标/原因**：
- **实际改动**：
- **关键文件**：
- **验证结果**：命令/检查方式、通过或失败、关键证据；未执行则说明原因。
- **遗留问题/下一步**：无则明确写“无”；否则记录恢复入口及复现条件。
```
