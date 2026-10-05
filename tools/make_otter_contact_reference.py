"""Annotated pose instructions only; the generated full cel is the game artwork."""
import base64
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design/walk-v10'
source=base64.b64encode((ROOT/'design/all-species-v3/masters/otter/adult.png').read_bytes()).decode()
for index,near,far in [(0,345,790),(6,465,665)]:
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<image width="1024" height="1024" href="data:image/png;base64,{source}"/>
<g fill="none" stroke="#ff3055" stroke-width="7"><ellipse cx="{near}" cy="864" rx="70" ry="28"/><path d="M 400 920 L {near} 920 M {near+(-12 if near>400 else 12)} 908 L {near} 920 L {near+(-12 if near>400 else 12)} 932"/></g>
<g fill="none" stroke="#6840ff" stroke-width="7"><ellipse cx="{far}" cy="864" rx="70" ry="28"/><path d="M 730 962 L {far} 962 M {far+(-12 if far>730 else 12)} 950 L {far} 962 L {far+(-12 if far>730 else 12)} 974"/></g>
<text x="40" y="60" font-family="sans-serif" font-size="28" fill="#222">PAW PLACEMENT GUIDE - preserve original chubby body</text>
<text x="40" y="100" font-family="sans-serif" font-size="23" fill="#dd2044">Red oval: tail-side foreground paw destination</text>
<text x="40" y="135" font-family="sans-serif" font-size="23" fill="#5131d0">Purple oval: scarf-side background paw destination</text></svg>'''
    (OUT/f'contact-guide-{index:02d}.svg').write_text(svg,encoding='utf8')
