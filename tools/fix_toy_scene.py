from pathlib import Path
p=Path('scripts/home_animation.gd')
s=p.read_text(encoding='utf-8').replace(',"home_toy_ball":"play","home_toy_mouse":"play"','')
p.write_text(s,encoding='utf-8')
p=Path('scripts/furniture_room.gd')
s=p.read_text(encoding='utf-8').replace('"home_toy_mouse":"playful"','"home_toy_mouse":"sniff"')
p.write_text(s,encoding='utf-8')
