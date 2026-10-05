"""Pose reference only: a short step with two distinct depth lanes, never game art."""
import math,json
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'design/walk-v8';P.mkdir(exist_ok=True)
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="1152" viewBox="0 0 1024 768"><rect width="1024" height="768" fill="#00ffff"/>']
records=[]
for i in range(12):
    t=i/12;x=i%4*256;y=i//4*256
    bob=1.2*math.cos(t*4*math.pi)
    feet=[];limbs={}
    for side,phase,gx,gy,color in [('far',(t+.5)%1,156,222,'#999'),('near',t,105,232,'#555')]:
        planted=phase<.6
        if planted:fx=gx+12-24*phase/.6;fy=gy
        else:
            q=(phase-.6)/.4
            # Endpoint derivative matches the backward contact velocity.
            fx=gx-12-24/.6*.4*q+(24+24/.6*.4)*(3*q*q-2*q*q*q)
            fy=gy-3*math.sin(math.pi*q)**2
        hy=(209 if side=='far' else 213)+bob
        feet.append(dict(side=side,x=fx+3,y=fy,planted=planted))
        limbs[side]=f'<path d="M {gx} {hy} Q {(gx+fx)/2+2} {(hy+fy)/2} {fx} {fy-4}" fill="none" stroke="{color}" stroke-width="12" stroke-linecap="round"/><ellipse cx="{fx+3}" cy="{fy-3}" rx="9" ry="3" fill="{color}" stroke="#333" stroke-width="1.5"/>'
    swing=3*math.cos(t*2*math.pi)
    parts.append(f'<g transform="translate({x},{y})">{limbs["far"]}<g transform="translate(0,{bob})"><ellipse cx="128" cy="176" rx="53" ry="40" fill="#ddd" stroke="#777" stroke-width="2"/><ellipse cx="132" cy="110" rx="48" ry="43" fill="#eee" stroke="#777" stroke-width="2"/><circle cx="138" cy="108" r="4"/><circle cx="159" cy="107" r="3"/><path d="M 145 120 L 153 120" stroke="#333" stroke-width="3"/><path d="M 96 160 Q 92 176 {101+swing} 184" fill="none" stroke="#888" stroke-width="12" stroke-linecap="round"/><path d="M 168 159 Q 174 173 {169-swing} 182" fill="none" stroke="#aaa" stroke-width="10" stroke-linecap="round"/></g>{limbs["near"]}</g>')
    records.append(dict(index=i,phase=t,feet=feet,body_bob=bob))
parts.append('</svg>')
(P/'lane-guide.svg').write_text(''.join(parts),encoding='utf8')
(P/'lane-plan.json').write_text(json.dumps(dict(stride=24/.6,stance_fraction=.6,keys=records),indent=2),encoding='utf8')
