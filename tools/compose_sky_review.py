from pathlib import Path
import json
from PIL import Image
folder=Path('builds/sky-arrival-review')
canvas=Image.new('RGB',(1200,360),'#faf8f3')
for index,name in enumerate(['toy_ball','toy_mouse','alarm_clock']):
 pet=Image.open(folder/(name+'-pet.png')).convert('RGBA')
 piece=Image.open(folder/(name+'.png')).convert('RGBA')
 data=json.loads((folder/(name+'-scene.json')).read_text())
 dx=data['piece_position'][0]-data['pet_position'][0]
 dy=data['piece_position'][1]-data['pet_position'][1]
 box=pet.getbbox()
 bounds=(min(box[0],dx)-15,min(box[1],dy)-15,max(box[2],dx+piece.width)+15,max(box[3],dy+piece.height)+15)
 frame=Image.new('RGBA',(bounds[2]-bounds[0],bounds[3]-bounds[1]))
 frame.alpha_composite(piece,(dx-bounds[0],dy-bounds[1]))
 frame.alpha_composite(pet,(-bounds[0],-bounds[1]))
 frame.thumbnail((390,350))
 canvas.paste(frame,(index*400+5,5),frame)
canvas.save(folder/'scenes.jpg')
