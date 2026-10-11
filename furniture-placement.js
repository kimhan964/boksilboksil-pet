// Coordinates and bounds are normalized so spacing also works after a viewport change.
export function positionClear(candidate,items,rectFor,isObstacle,gap={x:.014,y:.022}){
 const a=rectFor(candidate);
 if(a.x<.01||a.x+a.w>.99||a.y+a.h>.98)return false;
 return items.every(other=>{if(other===candidate||other.id===candidate.id||!isObstacle(other))return true;const b=rectFor(other);return a.x+a.w+gap.x<=b.x||b.x+b.w+gap.x<=a.x||a.y+a.h+gap.y<=b.y||b.y+b.h+gap.y<=a.y;});
}
export function freePosition(candidate,items,rectFor,isObstacle){
 if(positionClear(candidate,items,rectFor,isObstacle))return {x:candidate.x,y:candidate.y};
 const options=[];
 for(let y=.64;y<=.961;y+=.04)for(let x=.06;x<=.941;x+=.04)options.push({x,y,d:(x-candidate.x)**2+(y-candidate.y)**2});
 options.sort((a,b)=>a.d-b.d);
 for(const p of options)if(positionClear({...candidate,x:p.x,y:p.y},items,rectFor,isObstacle))return {x:p.x,y:p.y};
 return null;
}
