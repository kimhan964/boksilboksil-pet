import {positionClear} from './furniture-placement.js';
const clamp=(n,min,max)=>Math.max(min,Math.min(max,n));
export const MOVABLE_TOYS=['toy_ball','toy_mouse','acorn','basket'];
export function toyTouchRect(rect,width,height){
 const w=Math.min(width,Math.max(44,rect.w)),h=Math.min(height,Math.max(44,rect.h));
 return {x:clamp(rect.x+rect.w/2-w/2,0,width-w),y:clamp(rect.y+rect.h/2-h/2,0,height-h),w,h};
}
export function nearestToy(point,items,rectFor,width,height){
 return items.filter(f=>MOVABLE_TOYS.includes(f.id)).map(f=>{const r=toyTouchRect(rectFor(f),width,height);return {f,r,d:Math.hypot(point.x*width-r.x-r.w/2,point.y*height-r.y-r.h/2)};}).filter(({r})=>point.x*width>=r.x&&point.x*width<=r.x+r.w&&point.y*height>=r.y&&point.y*height<=r.y+r.h).sort((a,b)=>a.d-b.d)[0]?.f;
}
// Sweep the path instead of teleporting through furniture on a fast touch drag.
export function moveToy(item,target,items,rectFor,isObstacle){
 const end={x:clamp(target.x,.06,.94),y:clamp(target.y,.56,.96)};
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
export function roomFloorTarget(x,y,space='room'){return {x:clamp(x,.09,.91),y:clamp(y,space==='room'?.54:.72,.94)};}
