"""Technical gait diagram for image-generation reference, never shipped as pet art."""
import math,json
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'design/walk-v6';P.mkdir(exist_ok=True)
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="1152" viewBox="0 0 1024 768"><rect width="1024" height="768" fill="white"/>']
records=[]
for i in range(12):
    t=i/12; x=i%4*256;y=i//4*256
    bob=2*math.cos(t*4*math.pi)
    feet=[]
    for side,phase,gx,gy,color in [('far',(t+.5)%1,124,222,'#2879c8'),('near',t,132,228,'#d8493f')]:
        planted=phase<.6
        if planted:fx=gx+22-44*phase/.6;fy=gy
        else:
            q=(phase-.6)/.4;fx=gx-22+44*(q*q*(3-2*q));fy=gy-11*math.sin(q*math.pi)
        hx=gx;hy=205+bob;kx=(hx+fx)/2+3;ky=(hy+fy)/2
        feet.append(dict(side=side,x=fx,y=fy,planted=planted))
        if side=='far':far=f'<path d="M {hx} {hy} Q {kx} {ky} {fx} {fy-4}" fill="none" stroke="{color}" stroke-width="12" stroke-linecap="round"/><ellipse cx="{fx+3}" cy="{fy-3}" rx="12" ry="4" fill="{color}"/>'
        else:near=f'<path d="M {hx} {hy} Q {kx} {ky} {fx} {fy-4}" fill="none" stroke="{color}" stroke-width="12" stroke-linecap="round"/><ellipse cx="{fx+3}" cy="{fy-3}" rx="12" ry="4" fill="{color}"/>'
    parts.append(f'<g transform="translate({x},{y})"><text x="12" y="20" font-size="13" fill="#222">{i+1:02d}</text><path d="M 75 233 H 187" stroke="#bbb" stroke-width="1"/>{far}<ellipse cx="128" cy="174" rx="43" ry="34" fill="#ddd" stroke="#777" stroke-width="2"/><ellipse cx="132" cy="110" rx="48" ry="43" fill="#eee" stroke="#777" stroke-width="2"/><circle cx="138" cy="108" r="4"/><circle cx="159" cy="107" r="3"/><path d="M 145 120 L 153 120" stroke="#333" stroke-width="3"/>{near}<path d="M 102 160 Q 98 177 {109+8*math.cos(t*2*math.pi)} 187" fill="none" stroke="#888" stroke-width="10" stroke-linecap="round"/><path d="M 158 159 Q 169 173 {159-5*math.cos(t*2*math.pi)} 184" fill="none" stroke="#aaa" stroke-width="8" stroke-linecap="round"/></g>')
    records.append(dict(index=i,phase=t,feet=feet,body_bob=bob))
parts.append('</svg>');(P/'biped-contact-guide.svg').write_text(''.join(parts),encoding='utf8');(P/'biped-contact-plan.json').write_text(json.dumps(dict(stride=44/.6,stance_fraction=.6,keys=records),indent=2),encoding='utf8')
