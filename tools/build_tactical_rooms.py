from pathlib import Path
import csv,json,math
from shapely.geometry import Polygon,LineString,Point,box
from shapely.geometry.polygon import orient
from shapely.ops import unary_union,triangulate
from shapely import constrained_delaunay_triangles
p=Path(__file__).resolve().parents[1]
configs=[('camp','破营侧道',2500,500,2500),('sidecourt','折院迂回',850,2850,900),('passage','断墙长廊',2300,550,2300),('muster','废营纵深',2700,600,2500),('captain_court','主将前庭',700,2850,900)]
def court(cx,cy,w,h):
 return Polygon([(cx-w*.5+100,cy-h*.5),(cx+w*.25,cy-h*.5-70),(cx+w*.5,cy-h*.25),(cx+w*.5-50,cy+h*.35),(cx+w*.22,cy+h*.5),(cx-w*.4,cy+h*.5-30),(cx-w*.5,cy+h*.15),(cx-w*.5-50,cy-h*.2)])
def coords(ring): return [[round(x,2),round(y,2)] for x,y in list(ring.coords)[:-1]]
rows=[]
for index,(id,name,ny,my,fy) in enumerate(configs):
 areas=[court(850,ny,1250,1050),court(2850,my,1250,950),court(5150,fy,1400,1150)]
 main_a=[[1300,ny],[1750,ny],[1750,my],[2400,my]]
 main_b=[[3300,my],[3900,my],[3900,fy],[4700,fy]]
 by=max(250,min(3500,my+(650 if my>ny else -650)))
 cy=max(250,min(3500,fy+(550 if fy>my else -550)))
 flank_a=[[1100,ny+180],[1250,ny+180],[1250,by],[2050,by],[2050,my+280],[2550,my+280]]
 flank_b=[[3150,my+250],[3500,my+250],[3500,cy],[4350,cy],[4350,fy+300],[4900,fy+300]]
 paths=[main_a,main_b,flank_a,flank_b]
 def winding(path,route):
  points=[]
  for a,b in zip(path,path[1:]):
   dx,dy=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dy);steps=max(1,math.ceil(length/180))
   for j in range(steps):
    t=j/steps; sway=math.sin(math.pi*t)*math.sin(t*math.pi*2+route*.7)*55
    points.append((a[0]+dx*t-dy/length*sway,a[1]+dy*t+dx/length*sway))
  points.append(path[-1]);return points
 corridors=[]
 for i,path in enumerate(paths):
  line=winding(path,i)
  # Overlapping variable-radius areas make widening pockets and rounded shoulders.
  strips=[LineString([a,b]).buffer((177 if i<2 else 145)+12*math.sin(j*.9+i),quad_segs=2) for j,(a,b) in enumerate(zip(line,line[1:]))]
  corridors.extend(strips)
 geo=orient(unary_union(areas+corridors).simplify(12,preserve_topology=True),sign=1)
 assert geo.geom_type=='Polygon',geo.geom_type
 covers=[[770,ny-250,290,100],[1080,ny-100,110,300],[2690,my-160,130,360],[2820,my+100,300,110],[4960,fy-270,320,110],[4930,fy+180,130,280],[5440,fy+210,220,100]]
 cover_geo=unary_union([box(x,y,x+w,y+h) for x,y,w,h in covers])
 walk=geo.difference(cover_geo).buffer(-48)
 cells=[[x,y] for y in range(95) for x in range(160) if walk.contains(Point(x*40+20,y*40+20))]
 def safe(pos):
  if walk.contains(Point(*pos)): return pos
  return min([[x*40+20,y*40+20] for x,y in cells],key=lambda q:(q[0]-pos[0])**2+(q[1]-pos[1])**2)
 spawns=[safe([760,ny+100]),safe([1190,ny+80]),safe([2570,my-180]),safe([3100,my-220]),safe([4800,fy-100]),safe([5420,fy-80]),safe([5350,fy+360]),safe([5100,fy+350])]
 units=['soldier','soldier','soldier','archer','soldier','archer','archer','horn' if index in [2,3] else 'soldier']
 if index==4:units[4]='boss'
 # A peek shelter covers a flank rest point. The opening faces right.
 shelter=[3150,my-70,210,160]
 supplies=[safe([1900,by]),safe([4170,cy])]
 outer=box(0,0,6400,3800).difference(geo)
 triangles=[]
 for t in constrained_delaunay_triangles(outer).geoms:
  triangles.extend(coords(t.exterior))
 row=dict(id=id,name=name,outline=coords(geo.exterior),holes=[coords(h) for h in geo.interiors],entry=safe([370,ny+100]),exit=safe([5650,fy+100]),obstacles=covers,spawns=spawns,units=units,world_size=[6400,3800],nav_cells=cells,terrain_vertices=triangles,main_route=[[370,ny+100],[850,ny]]+main_a+[[2850,my]]+main_b+[[5150,fy],[5650,fy+100]],branches=[flank_a,flank_b],supplies=supplies,sight_screens=[{'rect':shelter,'direction':[1,0]}],zones=[{'name':'近距交火区','at':[850,ny]},{'name':'中转通道','at':[2850,my]},{'name':'远射阵地','at':[5150,fy]}])
 rows.append(row)
with (p/'data/rooms.csv').open('w',encoding='utf-8',newline='') as f:
 w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows([{k:json.dumps(v,separators=(',',':'),ensure_ascii=False) if not isinstance(v,str) else v for k,v in r.items()} for r in rows])
(p/'source_assets/tactical_layout_generation.json').write_text(json.dumps({'description':'Three combat spaces connected by two bent main links and two flank loops. CSV is runtime authority.','configurations':configs},ensure_ascii=False,indent=2),encoding='utf-8')
print([(r['id'],len(r['outline']),len(r['holes']),len(r['nav_cells'])) for r in rows])
