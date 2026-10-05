"""Four-beat, three-support-foot gait diagram for full-image animal generation."""
import json,math
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'design/walk-v6'
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="1152" viewBox="0 0 1024 768"><rect width="1024" height="768" fill="white"/>'];records=[]
for i in range(12):
    t=i/12;parts=[];feet=[]
    for name,phase,hx,ground,color in [('hind_far',(t+.5)%1,89,221,'#999'),('front_far',(t+.75)%1,151,221,'#999'),('hind_near',t,95,228,'#555'),('front_near',(t+.25)%1,157,228,'#555')]:
        grounded=phase<.75
        if grounded:x=hx+16-32*phase/.75;y=ground
        else:
            q=(phase-.75)/.25;x=hx-16+32*q*q*(3-2*q);y=ground-8*math.sin(q*math.pi)
        feet.append(dict(name=name,x=x,y=y,grounded=grounded))
        parts.append(f'<path d="M {hx} 202 Q {(hx+x)/2} 213 {x} {y-3}" fill="none" stroke="{color}" stroke-width="11" stroke-linecap="round"/><ellipse cx="{x+2}" cy="{y-3}" rx="10" ry="4" fill="{color}"/>')
    assert sum(f['grounded'] for f in feet)>=3
    svg.append(f'<g transform="translate({i%4*256},{i//4*256})"><text x="12" y="20" font-size="13" fill="#222">{i+1:02d}</text>'+''.join(parts[:2])+'<ellipse cx="122" cy="175" rx="53" ry="33" fill="#ddd" stroke="#777" stroke-width="2"/><ellipse cx="165" cy="131" rx="42" ry="39" fill="#eee" stroke="#777" stroke-width="2"/>'+''.join(parts[2:])+'<circle cx="171" cy="128" r="4"/><circle cx="190" cy="126" r="3"/><path d="M 183 140 L 191 140" stroke="#333" stroke-width="3"/></g>')
    records.append(dict(index=i,phase=t,feet=feet))
svg.append('</svg>');(p/'quadruped-contact-guide.svg').write_text(''.join(svg),encoding='utf8');(p/'quadruped-contact-plan.json').write_text(json.dumps(dict(stride=32/.75,stance_fraction=.75,keys=records),indent=2),encoding='utf8')
