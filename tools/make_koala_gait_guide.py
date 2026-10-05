"""Technical pose reference for image generation. Never shipped as pet artwork."""
import json, math
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'design/walk-v13/koala'
P.mkdir(parents=True,exist_ok=True)
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="1152" viewBox="0 0 1024 768"><rect width="1024" height="768" fill="#00ffff"/>']
records=[]
for i in range(12):
 t=i/12; bob=1.3*math.cos(4*math.pi*t); lean=1.4*math.sin(2*math.pi*t)
 limbs={}; feet=[]
 for side,phase,gx,gy,color in [('far',t,159,229,'#aaa298'),('near',(t+.5)%1,104,233,'#c9c1b9')]:
  planted=phase<.6
  if planted: fx=gx+11-22*phase/.6; fy=gy
  else:
   q=(phase-.6)/.4
   fx=gx-11-22/.6*.4*q+(22+22/.6*.4)*(3*q*q-2*q*q*q)
   fy=gy-7*math.sin(math.pi*q)**2
  feet.append(dict(side=side,x=fx+3,y=fy,planted=planted))
  limbs[side]=f'<path d="M {gx+lean} {211+bob} Q {gx+lean+3} {221+bob} {fx} {fy-5}" fill="none" stroke="#523c34" stroke-width="18" stroke-linecap="round"/><path d="M {gx+lean} {210+bob} Q {gx+lean+3} {221+bob} {fx} {fy-5}" fill="none" stroke="{color}" stroke-width="14" stroke-linecap="round"/><ellipse cx="{fx+3}" cy="{fy-4}" rx="14" ry="5" fill="{color}" stroke="#523c34" stroke-width="2"/>'
 swing=4*math.sin(2*math.pi*t)
 parts.append(f'<g transform="translate({i%4*256},{i//4*256})">{limbs["far"]}<g transform="translate({lean},{bob})"><ellipse cx="132" cy="184" rx="53" ry="39" fill="#c9c1b9" stroke="#523c34" stroke-width="2"/><ellipse cx="140" cy="186" rx="30" ry="34" fill="#fff9e9"/><ellipse cx="64" cy="81" rx="31" ry="45" fill="#c9c1b9" stroke="#523c34" stroke-width="2"/><ellipse cx="195" cy="79" rx="29" ry="44" fill="#c9c1b9" stroke="#523c34" stroke-width="2"/><ellipse cx="65" cy="84" rx="18" ry="28" fill="#fff9e9"/><ellipse cx="196" cy="82" rx="16" ry="27" fill="#fff9e9"/><ellipse cx="135" cy="111" rx="59" ry="47" fill="#c9c1b9" stroke="#523c34" stroke-width="2"/><ellipse cx="121" cy="120" rx="7" ry="9" fill="#211b18"/><ellipse cx="168" cy="118" rx="6" ry="8" fill="#211b18"/><ellipse cx="147" cy="126" rx="11" ry="16" fill="#4b4440"/><path d="M 87 153 Q 136 174 176 151 L 174 166 Q 131 181 86 165 Z" fill="#99a476" stroke="#523c34" stroke-width="2"/><path d="M 96 173 Q {93+swing} 187 {106+swing} 195" fill="none" stroke="#523c34" stroke-width="19" stroke-linecap="round"/><path d="M 96 173 Q {93+swing} 187 {106+swing} 195" fill="none" stroke="#c9c1b9" stroke-width="15" stroke-linecap="round"/><path d="M 175 174 Q {177-swing} 186 {172-swing} 193" fill="none" stroke="#523c34" stroke-width="15" stroke-linecap="round"/><path d="M 175 174 Q {177-swing} 186 {172-swing} 193" fill="none" stroke="#c9c1b9" stroke-width="11" stroke-linecap="round"/></g>{limbs["near"]}</g>')
 records.append(dict(index=i,phase=t,feet=feet,body_bob=bob,body_shift=lean))
parts.append('</svg>')
(P/'guide.svg').write_text(''.join(parts),encoding='utf8')
(P/'guide-plan.json').write_text(json.dumps(dict(stride=22/.6,stance_fraction=.6,keys=records),indent=2),encoding='utf8')
