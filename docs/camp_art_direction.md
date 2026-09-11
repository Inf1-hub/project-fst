# 军营废墟美术方向

依据用户提供的理想效果图：冷灰石地、断墙与枯木为基底，破旗、拒马、军需营帐和车轮形成有用途的物件组；橙色火盆只作局部暖色焦点。细节集中在边缘、遮蔽点和掩体脚下，战斗中心保留清楚的走位空间。不能把整张效果图当作背景贴在可玩区域后方。

本轮新增 `content/ruins/camp_atlas_v1.png`（1536×1024 RGBA），内置 image_gen 生成，无 CLI。首个请求因网络错误失败；重试成功。保留原始透明通道与原始像素，在运行时用 AtlasTexture 划分营帐、破旗拒马、残墙、火盆，按原比例绘制。生成结果没有严格遵循等分格，所以使用检查后的四个非等分区域，避免串图。

第三关样板额外布景配置为 `data/camp_landmarks.csv`。遮蔽点是可进入的设施，进入后降低透明度；它不是新增的实体碰撞掩体。外围军营布景仍在不可通行区。地面泥污、暗红痕迹为程序材质，不是实时战斗留下的痕迹。

火光使用共享渐变纹理和无阴影 PointLight2D，低/中/高最多 0/4/8 盏，按人物距离重新分配。低档保留火焰贴图。退出最后一个营地组件时释放静态渐变缓存。

生成提示词：

Transparent RGBA sprite sheet, 1536x1024, four isolated props in 2x2 cells with generous clear margins. True alpha outside objects; no background, labels, frames or checkerboard. Fixed elevated 55-degree three-quarter view for dark medieval realistic hand-painted game, cold grey weathered stone, dark timber, tattered oxblood cloth, subdued orange fire. Upper left: ruined red canvas army supply tent with barrels sacks a broken wheel and debris. Upper right: burgundy battle banner with spiked barricade, broken cart wheel, shields and a small flaming iron brazier, one asymmetric group. Lower left: broken limestone defensive wall with shattered arch at left tapering into low rubble right, ivy and dead shrubs. Lower right: a single flaming iron brazier on stone feet, tiny sparks, no other large props. Keep every prop fully inside its quadrant, no overlapping cells. Natural proportions, visible tops and fronts, intricate irregular silhouettes. Ground contact only, no floor rectangles, no characters. These are game assets, not an illustration of a whole battlefield.

当前仍与参考图有差距：建筑与岩体的重复、地面细节的自然程度、局部构图密度、动态火焰和接触阴影尚未达到效果图品质。已有素材接入和测试通过不等同于最终美术验收。
