import {hopFlight} from './rabbit-hop.js';
const clamp=v=>Math.max(0,Math.min(1,v));
const ease=v=>{v=clamp(v);return v*v*(3-2*v);};
export function choreMotion(elapsed,timing,type,hop){
 const {walk,work,return:back}=timing;
 const phase=elapsed<walk?'walk':elapsed<walk+work?'work':'return';
 const local=phase==='walk'?elapsed:phase==='work'?elapsed-walk:elapsed-walk-work;
 const duration=phase==='walk'?walk:phase==='work'?work:back;
 const p=clamp(local/duration),active=phase==='work';
 // Rabbit feet move only during authored flight; other pets keep a steady stride.
 const travel=hop?(Math.floor(local/hop.period)+ease(hopFlight(local,hop)))/(duration/hop.period):p;
 const intensity=active?ease(p/.22)*(1-ease((p-.80)/.20)):0;
 const toss=active&&p>.22&&p<.80?Math.sin(((p-.22)/.58*3%1)*Math.PI):0;
 return {phase,local,p,travel:active?1:phase==='return'?1-clamp(travel):clamp(travel),dir:phase==='return'?1:-1,
  intensity,lean:active?-.035*intensity:0,
  tilt:type==='water'?-.25*intensity:type==='plant'?-.20*toss:0,
  emit:active&&p>.25&&p<.78,
  label:phase==='walk'?'밭으로 총총':phase==='return'?'돌아가요':p<.22?'작업 준비':p>.80?'마무리':{plant:'씨앗 톡톡',water:'물 주기',harvest:'수확 쏙쏙',cook:'보글보글 요리'}[type]};
}
export function transformToolPoint(hand,point,angle,flip=1){
 return {x:hand.x+flip*(point.x*Math.cos(angle)-point.y*Math.sin(angle)),y:hand.y+point.x*Math.sin(angle)+point.y*Math.cos(angle)};
}
export function fallingParticle(start,end,u){
 u=clamp(u);return {x:start.x+(end.x-start.x)*u,y:start.y+(Math.max(start.y+2,end.y)-start.y)*u*u};
}
