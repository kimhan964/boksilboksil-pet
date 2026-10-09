"""Dense whole-pose walking candidate, staged until visual review passes."""
import argparse,json
import bake_wardrobe_v3 as bake
from bake_wardrobe_extras import keys
parser=argparse.ArgumentParser();parser.add_argument('--styles',nargs='+',default=['apron','vest','knit']);parser.add_argument('--direct',action='store_true');args=parser.parse_args()
work=bake.ROOT/'design/wardrobe-v3/motion/rabbit/adult/paw-continuity-v4'
bake.WORK=work
bake.DEST=bake.ROOT/'builds/wardrobe-paw-fix/rabbit/adult'
phases=[0,4,8,11,15,19,22,26,30,34,38,41,45,49,52,56,60]
for style in args.styles:
    if args.direct:
        from PIL import Image
        sheet=Image.open(work/f'{style}-direct-generated.png')
        w,h=sheet.size
        cels=[bake.key_generated(sheet.crop((round(i%4*w/4),round(i//4*h/4),round((i%4+1)*w/4),round((i//4+1)*h/4)))).resize((256,256),Image.Resampling.LANCZOS) for i in range(16)]
    else: cels=keys(work/f'{style}-generated.png')
    # Reject the remaining extended-paw landing drawing, rather than hide it
    # in interpolation. Its adjacent complete poses define the same timeline.
    indices=[i for i in range(16) if not (args.direct and style=='apron' and i==10)]
    frames=[]
    for k,i in enumerate(indices):
        end=indices[k+1] if k+1<len(indices) else 16
        frames+=bake.interpolate(cels[i],cels[end%16],phases[end]-phases[i],work/('direct-flow' if args.direct else 'flow')/style/str(i))
    spec=bake.pack(frames,style,'walk');spec['source_key_count']=len(indices);spec['key_phases']=[phases[i] for i in indices]
    (bake.DEST/style/'walk-spec.json').write_text(json.dumps(spec,indent=2))
    print(style,'dense walk candidate ready',flush=True)
