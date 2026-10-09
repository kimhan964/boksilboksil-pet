import json
from bake_wardrobe_v3 import WORK,DEST,interpolate,pack
from bake_wardrobe_extras import keys
phases=[0,8,16,23,30,38,45,53,60]
manifest=json.loads((DEST/'manifest.json').read_text())
for style in ['vest','knit','apron']:
    cels=keys(WORK/f'{style}-meals-generated.png')
    for row,bank in enumerate(['eat','drink']):
        frames=[]
        for k in range(8):
            frames+=interpolate(cels[row*8+k],cels[row*8+(k+1)%8],phases[k+1]-phases[k],WORK/'short-paws-baked'/style/(bank+'-v2')/str(k))
        manifest['styles'][style][bank]=pack(frames,style,bank)
    print('MEALS 8-key correction',style,flush=True)
(DEST/'manifest.json').write_text(json.dumps(manifest,indent=2))
