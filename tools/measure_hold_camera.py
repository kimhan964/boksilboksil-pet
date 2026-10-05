"""Measure existing immutable cels; write camera metadata, never edit artwork."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]

def measure(image,height,species):
    alpha=np.array(image.getchannel('A'))>127
    yy,xx=np.where(alpha)
    top=int(yy.min())
    band=alpha[top:min(256,top+round(height*(.48 if species in ['rabbit','red_panda'] else .36)))]
    rows=[np.where(row)[0] for row in band if row.any()]
    widths=np.array([row[-1]-row[0]+1 for row in rows],float)
    width=float(np.percentile(widths,95))
    centers=[(row[0]+row[-1])/2 for row in rows if row[-1]-row[0]+1>=width*.95]
    return {'width':width,'pivot':[float(np.median(centers)),top+height*.20]}

def run():
    result={}
    for folder in sorted((ROOT/'assets/struggle-v1').iterdir()):
        if not folder.is_dir():continue
        species=folder.name; meta=json.loads((folder/'manifest.json').read_text())
        for stage,spec in meta['stages'].items():
            banks={}
            files=[('struggle-v1',folder/spec['file'],60,spec['reference_height'])]

            for name,path,count,height in files:
                sheet=Image.open(path).convert('RGBA')
                entries=[measure(sheet.crop((i%8*256,i//8*256,i%8*256+256,i//8*256+256)),height,species) for i in range(count)]
                banks[name]={'height':height,'entries':entries}
            target=float(np.median([e['width'] for e in banks['struggle-v1']['entries']]))/spec['reference_height']
            for name,bank in banks.items():
                entries=bank['entries']; widths=[e['width'] for e in entries]
                for i,entry in enumerate(entries):
                    # Smooth pixel-boundary noise. The loop wraps; transitions
                    # keep exact endpoint calibration for seamless handoffs.
                    if name=='struggle-v1':
                        width=sum(widths[(i+j)%len(widths)]*weight for j,weight in zip(range(-3,4),[1,2,3,4,3,2,1]))/16
                    else: width=widths[i]
                    entry['scale']=target*bank['height']/width
                del bank['height']
                banks[name]=entries
            result[f'{species}/{stage}']=banks
    dest=ROOT/'assets/hold-camera-v2.json'
    dest.write_text(json.dumps(result,separators=(',',':')))
    factors=[e['scale'] for banks in result.values() for entries in banks.values() for e in entries]
    print('HOLD_CAMERA',len(result),'age banks',len(factors),'measurements; scale range',min(factors),max(factors))

if __name__=='__main__':run()

