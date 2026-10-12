import {positionClear} from './furniture-placement.js';
const clamp=(n,min,max)=>Math.max(min,Math.min(max,n));
export const MOVABLE_TOYS=['toy_ball','toy_mouse','acorn','basket'];
export const toyIconFile=id=>MOVABLE_TOYS.includes(id)?'desktop/'+id+'.webp':'ui-icons/play.png';
export const playObstacle=f=>Boolean(f.uiBlock)||MOVABLE_TOYS.includes(f.id);
export function toyTouchRect(rect,width,height){
 const w=Math.min(width,Math.max(44,rect.w)),h=Math.min(height,Math.max(44,rect.h));
 return {x:clamp(rect.x+rect.w/2-w/2,0,width-w),y:clamp(rect.y+rect.h/2-h/2,0,height-h),w,h};
}
export function nearestToy(point,items,rectFor,width,height){
 return items.filter(f=>MOVABLE_TOYS.includes(f.id)).map(f=>{const r=toyTouchRect(rectFor(f),width,height);return {f,r,d:Math.hypot(point.x*width-r.x-r.w/2,point.y*height-r.y-r.h/2)};}).filter(({r})=>point.x*width>=r.x&&point.x*width<=r.x+r.w&&point.y*height>=r.y&&point.y*height<=r.y+r.h).sort((a,b)=>a.d-b.d)[0]?.f;
}
// Sweep the path instead of teleporting through furniture on a fast touch drag.
export function moveToy(item,target,items,rectFor,isObstacle){
 const r=rectFor(item),marginX=r.w/2+.015;
 const end={x:clamp(target.x,marginX,1-marginX),y:clamp(target.y,r.h+.015,.96)};
 const steps=Math.max(1,Math.ceil(Math.hypot(end.x-item.x,end.y-item.y)/.01));
 const dx=(end.x-item.x)/steps,dy=(end.y-item.y)/steps;let next={...item};
 for(let i=0;i<steps;i++){
  const both={...next,x:next.x+dx,y:next.y+dy};
  if(positionClear(both,items,rectFor,isObstacle)){next=both;continue;}
  const horizontal={...next,x:next.x+dx},vertical={...next,y:next.y+dy};
  if(dx&&positionClear(horizontal,items,rectFor,isObstacle))next=horizontal;
  else if(dy&&positionClear(vertical,items,rectFor,isObstacle))next=vertical;
  else break;
 }
 return {x:next.x,y:next.y};
}
export function roomFloorTarget(x,y,space='room'){return {x:clamp(x,.06,.94),y:clamp(y,space==='room'?.70:.80,.94)};}
export function toyLanding(item,target,items,rectFor){
 const r=rectFor(item),x=clamp(target.x,r.w/2+.015,1-r.w/2-.015),y=clamp(target.y,.72,.96),options=[{x,y,d:0}];
 for(let py=.72;py<=.961;py+=.04)for(let px=r.w/2+.015;px<=1-r.w/2-.015;px+=.04)options.push({x:px,y:py,d:(px-x)**2+(py-y)**2});
 options.sort((a,b)=>a.d-b.d);
 for(const p of options)if(positionClear({...item,x:p.x,y:p.y},items,rectFor,playObstacle))return {x:p.x,y:p.y};
 return null;
}
export function toyDropFrame(elapsed,startOffset){
 const t=Math.max(0,elapsed),fall=.65,bounce=.4;
 if(t<fall)return {offset:Math.min(0,startOffset)*(1-(t/fall)**2),done:false};
 if(t<fall+bounce){const p=(t-fall)/bounce;return {offset:-.045*Math.sin(Math.PI*p)*(1-p),done:false};}
 return {offset:0,done:true};
}

