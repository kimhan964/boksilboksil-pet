"""Inventory all current species-v3 cels for subsequent visual/runtime review.

Bounds vary with actions and are not a scale or naturalness verdict. This audit
finds missing/blank/canvas-edge cels and records evidence, without editing art.
"""
import hashlib,json
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'design/all-animal-motion-review/asset-inventory'
out.mkdir(parents=True,exist_ok=True)
banks=[]
for path in sorted((ROOT/'assets/species-v3').glob('*/manifest.json')):
    manifest=json.loads(path.read_text('utf8'));cw,ch=manifest['canvas']
    for stage,data in manifest['stages'].items():
        for action,sequence in data['sequences'].items():
            record=dict(species=path.parent.name,stage=stage,action=action,file=str((path.parent/sequence['file']).relative_to(ROOT)),declared_count=sequence['count'],frames=[],errors=[])
            atlas_path=path.parent/sequence['file']
            if not atlas_path.exists():
                record['errors'].append('missing_atlas');banks.append(record);continue
            atlas=Image.open(atlas_path).convert('RGBA');hashes=set();heights=[]
            for i in range(sequence['count']):
                x=i%sequence['columns']*cw;y=i//sequence['columns']*ch
                frame=atlas.crop((x,y,x+cw,y+ch));alpha=frame.getchannel('A')
                bbox=alpha.point(lambda v:255 if v>16 else 0).getbbox()
                flags=[]
                if x+cw>atlas.width or y+ch>atlas.height:flags.append('outside_atlas')
                if not bbox:flags.append('blank')
                elif bbox[0]<=0 or bbox[1]<=0 or bbox[2]>=cw or bbox[3]>=ch:flags.append('canvas_edge')
                if bbox:heights.append(bbox[3]-bbox[1])
                hashes.add(hashlib.sha256(frame.tobytes()).hexdigest())
                record['frames'].append(dict(index=i,bbox=bbox,flags=flags))
            record['distinct_cels']=len(hashes)
            record['silhouette_height_range']= [min(heights),max(heights)] if heights else None
            record['flagged_frames']=sum(bool(f['flags']) for f in record['frames'])
            banks.append(record)
summary=dict(species=len({b['species'] for b in banks}),stages=len({(b['species'],b['stage']) for b in banks}),banks=len(banks),declared_frames=sum(b['declared_count'] for b in banks),flagged_banks=[{k:b[k] for k in ['species','stage','action','errors','flagged_frames'] if k in b} for b in banks if b['errors'] or b.get('flagged_frames')],limits='Static atlas coverage and alpha bounds only. Includes legacy walking banks; does not cover modern walk-v12, expressions, outfits or native playback. A canvas-edge flag requires visual confirmation. No aesthetic or gait approval.')
(out/'species-v3-inventory.json').write_text(json.dumps(dict(summary=summary,banks=banks),indent=2),encoding='utf8')
print(json.dumps(summary,indent=2))
