# 冷灰废墟场景组件

生成方式：内置 image_gen 工具（非 CLI）。资源：`content/ruins/scenery_atlas_v1.png`，1536×1024，真实 RGBA；3×2 图集，运行时读取各格透明包围盒，保持原比例。导入开启 mipmaps，尺寸上限 1536。原始图未改动像素。

六个组件：石灰岩丘、坍塌礼拜堂、枯山楂树与常春藤、低岩台、藤蔓残楼、荆棘灌木。建筑不构成可进入房间，只作不可通行区布景。贴图朝向固定，不旋转立面。

生成提示词：

Create a production game environment sprite atlas on TRUE transparent alpha background, no checkerboard baked in. 1536x1024 landscape. Six separate isolated props in strict 3 columns by 2 rows, each fully contained within its cell with generous transparent margins and no overlap. All share a fixed elevated three quarter top down camera at 55 degrees looking down, like a dark medieval isometric action RPG, cold grey realistic hand painted detailed stone and muted olive vegetation, diffuse overcast daylight upper left. Top row: left a substantial irregular limestone crag rocky hill with weathered boulders and dead moss, center a roofless ruined gothic chapel with collapsed roof rubble and broken arch one connected natural mass, right a dense group of 3 gnarled leafless hawthorn trees with ivy roots and dry bramble. Bottom row: left broad low limestone outcrop rock bank, center collapsed medieval masonry building fragment covered in dark ivy, right an irregular dense mass of grey thorn bushes dry olive shrubs and small pale rocks. Objects grounded with subtle short contact shading only; no rectangular bases no ground tiles no horizon no sky no text no frames no grid lines. Organic silhouettes, natural volume, clear ground contact at bottom, restrained contrast. This is an atlas of six large scenery props for inaccessible terrain, not a complete map.
