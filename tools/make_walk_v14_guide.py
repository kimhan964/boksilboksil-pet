"""Technical pose guide only, never shipped as character artwork."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
root=Path(__file__).resolve().parents[1]
out=root/'design/walk-v14';out.mkdir(exist_ok=True)
poses=[(380,895,690,895),(386,880,677.5,895),(405,864,665,895),(424,880,652.5,895),(430,895,640,895),(417.5,895,646,880),(405,895,665,864),(392.5,895,684,880)]
sheet=Image.new('RGB',(2048,1024),'white')
for i,(nx,ny,fx,fy) in enumerate(poses):
    im=Image.new('RGB',(1024,1024),'white');d=ImageDraw.Draw(im)
    bob=[0,3,5,3,0,3,5,3][i]
    d.ellipse((320,460-bob,790,850-bob),outline='#999999',width=5)
    d.ellipse((270,170-bob,820,590-bob),outline='#999999',width=5)
    d.line((180,895,880,895),fill='#dddddd',width=2)
    d.line((625,790-bob,fx,fy-24),fill='#4084ca',width=15)
    d.ellipse((fx-49,fy-37,fx+49,fy),fill='#a1c8ed',outline='#4084ca',width=3)
    d.line((430,780-bob,nx,ny-24),fill='#e58269',width=17)
    d.ellipse((nx-52,ny-38,nx+52,ny),fill='#f8b09a',outline='#e58269',width=3)
    d.text((30,25),f'{i}: near = orange, far = blue',fill='black',stroke_width=1)
    sheet.paste(im.resize((512,512)),(i%4*512,i//4*512))
sheet.save(out/'biped-guide-8.png')
(out/'biped-guide-8.json').write_text(json.dumps({'purpose':'pose guide; not game art','poses':poses,'source_stride':100,'ground':895},indent=2))
