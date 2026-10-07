import json
from pathlib import Path
from PIL import Image, ImageDraw
folder=Path('builds/toy-pursuit-review')
data=json.loads((folder/'frames.json').read_text())
for toy in ['toy_mouse','toy_ball']:
 rows=[r for r in data if r['prefix'].startswith(toy)]
 records=[]
 for row in rows:
  with Image.open(folder/(row['prefix']+'-pet.png')) as image:
   box=image.getbbox()
   if not box: continue
   pet=image.crop(box).convert('RGBA')
  piece=Image.open(folder/(row['prefix']+'-piece.png')).convert('RGBA')
  px=row['pet'][0]+box[0];py=row['pet'][1]+box[1]
  records.append((pet,piece,px,py,row))
 left=min(min(px,r['piece'][0]) for pet,piece,px,py,r in records)-16
 top=min(min(py,r['piece'][1]) for pet,piece,px,py,r in records)-16
 right=max(max(px+pet.width,r['piece'][0]+piece.width) for pet,piece,px,py,r in records)+16
 bottom=max(max(py+pet.height,r['piece'][1]+piece.height) for pet,piece,px,py,r in records)+16
 frames=[]
 for pet,piece,px,py,row in records:
  frame=Image.new('RGBA',(right-left,bottom-top),'#faf8f3')
  frame.alpha_composite(piece,(row['piece'][0]-left,row['piece'][1]-top))
  frame.alpha_composite(pet,(px-left,py-top))
  frame=frame.convert('RGB').resize((2*(right-left),2*(bottom-top)))
  frames.append(frame)
 frames[0].save(folder/(toy+'.gif'),save_all=True,append_images=frames[1:],duration=200,loop=0)
 sheet=Image.new('RGB',(frames[0].width*4,frames[0].height*2),'#faf8f3')
 for i,index in enumerate([0,8,16,24,32,40,48,56]):
  sheet.paste(frames[min(index,len(frames)-1)],(i%4*frames[0].width,i//4*frames[0].height))
 sheet.save(folder/(toy+'-review.jpg'))
 print(toy,'rendered frames',len(frames),'states',sorted(set(r['stage'] for r in rows)))
