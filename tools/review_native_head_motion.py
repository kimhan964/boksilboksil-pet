"""Measure the head silhouette in real captures; never infer quality from fps alone.

The upper-head alpha centroid is a proxy, not a skeletal landmark. Report its
cycle-relative excursion and multi-sample reversal separately from raster noise.
"""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw

p=argparse.ArgumentParser();p.add_argument('capture_root');p.add_argument('--output',required=True);p.add_argument('--report',default='walk-native-report.json');a=p.parse_args()
root=Path(a.capture_root);out=Path(a.output);out.mkdir(parents=True,exist_ok=True)
report=json.loads((root/a.report).read_text('utf8'));results=[]
for bank in report['results']:
    rows=[]
    for sample in bank['frames']:
        im=Image.open(root/sample['file']).convert('RGBA');v=np.asarray(im,dtype=float);alpha=v[:,:,3]/255
        ys,xs=np.where(alpha>.5)
        # Fixed local band across a bank: upper 44% of the first frame's body.
        if not rows: band=(int(ys.min()),int(ys.min()+.44*(ys.max()-ys.min())))
        weight=alpha[band[0]:band[1]];x=np.arange(im.width)[None,:]
        head_x=float((weight*x).sum()/weight.sum())+sample['window'][0]
        y=np.arange(band[0],band[1])[:,None]
        head_y=float((weight*y).sum()/weight.sum())+sample['window'][1]
        rows.append(dict(time=sample['time'],index=sample['index'],bank=sample['bank'],file=sample['file'],head_x=head_x,head_y=head_y,root_x=sample['feet'][0],root_y=sample['feet'][1],head_offset=head_x-sample['feet'][0],head_offset_y=head_y-sample['feet'][1],body_bbox_size=[int(xs.max()-xs.min()+1),int(ys.max()-ys.min()+1)]))
    all_rows=rows;rows=[r for r in rows if r['bank']=='walk']
    t=np.array([r['time'] for r in rows]);h=np.array([r['head_x'] for r in rows]);r=np.array([r['root_x'] for r in rows]);off=h-r
    direction=float(np.sign(r[-1]-r[0]));span=6
    steps=(h[span:]-h[:-span])*direction;speed=steps/(t[span:]-t[:-span])
    summary=dict(species=bank['species'],stage=bank['stage'],captures=len(rows),head_band=list(band),root_speed=float(abs((r[-1]-r[0])/(t[-1]-t[0]))),head_offset_range_px=float(np.ptp(off)),head_100ms_travel_min_px=float(steps.min()),head_100ms_travel_max_px=float(steps.max()),head_100ms_speed_min=float(speed.min()),head_100ms_speed_max=float(speed.max()),reversal_windows_over_quarter_pixel=int((steps<-.25).sum()),limits='Upper-head silhouette centroid; rotation/shape changes affect this proxy. Must inspect source images, soles, and actual displayed motion.',samples=rows)
    expected=np.abs(r[span:]-r[:-span]);summary['slow_window_fraction']=float(np.mean(steps<expected*.25));summary['fast_window_fraction']=float(np.mean(steps>expected*2))
    vertical=np.array([r['head_offset_y'] for r in rows]);sizes=np.array([r['body_bbox_size'] for r in rows])
    summary['vertical_review']=dict(head_offset_range_px=float(np.ptp(vertical)),max_adjacent_head_offset_jump_px=float(np.max(np.abs(np.diff(vertical)))),body_bbox_width_range_px=[int(sizes[:,0].min()),int(sizes[:,0].max())],body_bbox_height_range_px=[int(sizes[:,1].min()),int(sizes[:,1].max())],limits='Fixed upper-band alpha centroid and full silhouette bounds. Body pose, tail/ear motion and rasterization change these values; bounds are not sprite scale or skeletal landmarks. Inspect sequence before judging bob, stretch or jitter.')
    summary['loop_head_jumps_px']=[b['head_x']-a['head_x'] for a,b in zip(rows,rows[1:]) if a['index']-b['index']>40]
    summary['loop_head_y_jumps_px']=[b['head_offset_y']-a['head_offset_y'] for a,b in zip(rows,rows[1:]) if a['index']-b['index']>40]
    stops=[(i,a,b) for i,(a,b) in enumerate(zip(all_rows,all_rows[1:])) if a['bank']=='walk' and b['bank']!='walk']
    summary['stop_head_jumps_px']=[b['head_x']-a['head_x'] for _,a,b in stops]
    summary['stop_head_y_jumps_px']=[b['head_offset_y']-a['head_offset_y'] for _,a,b in stops]
    summary['idle_captures']=len(all_rows)-len(rows)
    if stops:
        idx=stops[0][0];contact=Image.new('RGB',(1280,4*190),'#fff8ed');cd=ImageDraw.Draw(contact)
        for j,k in enumerate([max(0,idx-9),max(0,idx-6),max(0,idx-3),idx,idx+1,min(len(all_rows)-1,idx+4),min(len(all_rows)-1,idx+10),len(all_rows)-1]):
            sample=all_rows[k];im=Image.open(root/sample['file']).convert('RGBA').crop((0,34,640,224));gx=j%2*640;gy=j//2*190;contact.paste(im,(gx,gy),im);cd.text((gx+5,gy+4),f"{sample['bank']} {sample['index']} t={sample['time']:.3f}",fill='#513d32')
        contact.save(out/(bank['species']+'-'+bank['stage']+'-stop-contact.png'))
    results.append(summary)
    board=Image.new('RGB',(1200,560),'#fff8ed');d=ImageDraw.Draw(board)
    for line,(label,values,color) in enumerate([('Head versus root (px)',off-off[0],'#c26a30'),('Forward travel over ~100 ms (px)',steps,'#428b83')]):
        top=35+line*270;lo=min(-1,float(values.min()));hi=max(1,float(values.max()));d.text((15,top-22),label+f'  range {values.min():.2f}..{values.max():.2f}',fill='#513d32')
        yy=lambda v:top+210-(v-lo)/(hi-lo)*210
        d.line((35,yy(0),1180,yy(0)),fill='#c5bbb0')
        pts=[(35+i/(len(values)-1)*1145,yy(v)) for i,v in enumerate(values)];d.line(pts,fill=color,width=2)
    name=bank['species']+'-'+bank['stage'];board.save(out/(name+'-head-motion.png'))
(out/'head-motion-review.json').write_text(json.dumps(results,indent=2),encoding='utf8')
print(json.dumps([{k:v for k,v in x.items() if k!='samples'} for x in results],indent=2))
