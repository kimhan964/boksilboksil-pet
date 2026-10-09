"""Record verified preview coverage; never mark public gameplay as complete."""
import json,hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
plan_path=root/'design/wardrobe-v3/catalog-plan.json'
plan=json.loads(plan_path.read_text(encoding='utf-8'))
rows=[]
for pet in plan['species']:
    species=pet['id'];manifest=root/f'assets/wardrobe-motion-v3/{species}/adult/manifest.json'
    data=json.loads(manifest.read_text())
    report=json.loads((root/f'builds/wardrobe-v3-native/{species}/report.json').read_text())
    assert len(data['styles'])==3 and not report['failures'],species
    rows.append({'species':species,'styles':3,'cels':sum(s['count'] for b in data['styles'].values() for s in b.values()),'native_checks':report['checks'],'native_failures':report['failures'],'canonical_manifest_sha256':hashlib.sha256(json.dumps(data,sort_keys=True,separators=(',',':')).encode()).hexdigest()})
    pet['runtime_preview_applied']=True
    pet['runtime_applied']=False
    pet['preview_stage']='adult'
plan['production_status']='16 species / 48 adult outfits in isolated native animation preview; public purchase game wardrobe, baby, furniture, sleep and slapstick coverage pending.'
plan_path.write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8',newline='\n')
summary={'preview_only':True,'species':rows,'total_cels':sum(r['cels'] for r in rows),'native_checks':sum(r['native_checks'] for r in rows),'public_purchase_release_updated':False,'visual_scope':'Source pose sheets and sampled walk/struggle/bridge contacts reviewed; automated checks verify geometry and coverage, not aesthetic perfection.'}
(root/'design/wardrobe-v3/motion/verified-preview.json').write_text(json.dumps(summary,indent=2),newline='\n')
print(json.dumps({'species':len(rows),'outfits':48,'cels':summary['total_cels'],'native_checks':summary['native_checks']}))
