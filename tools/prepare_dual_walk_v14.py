"""Split a reviewed two-age, four-key whole-character sheet into bake inputs."""
import argparse,json,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('species');p.add_argument('--cycle',type=float,default=2.2);p.add_argument('--build',action='store_true');a=p.parse_args()
folder=ROOT/'design/walk-v14'/a.species
subprocess.run([sys.executable,str(ROOT/'tools/inspect_whole_sheet.py'),str(folder/'generated-dual-4.png'),str(folder/'dual-extracted'),'--components'],check=True,stdout=subprocess.DEVNULL)
records=json.loads((folder/'dual-extracted/measurements.json').read_text())
for age,offset in [('adult',0),('baby',4)]:
    dest=folder/age;dest.mkdir(exist_ok=True);selected=[]
    for i,rec in enumerate(records[offset:offset+4]):
        shutil.copyfile(folder/'dual-extracted'/rec['file'],dest/f'key-{i:02d}.png')
        override=dest/f'whole-key-{i:02d}-override.png'
        if override.exists():shutil.copyfile(override,dest/f'key-{i:02d}.png')
        selected.append({**rec,'file':f'key-{i:02d}.png','index':i})
    (dest/'measurements.json').write_text(json.dumps(selected,indent=2))
    (dest/'frame-order.json').write_text('[0,1,2,3]')
    cmd=[sys.executable,str(ROOT/'tools/build_whole_sheet_v14.py'),str(dest),'--species',a.species,'--stage',age,'--cycle',str(a.cycle)]
    if a.build:cmd.append('--build')
    if a.species in ['puppy','lamb','hedgehog']:cmd.append('--quadruped')
    subprocess.run(cmd,check=True)
