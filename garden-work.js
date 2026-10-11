import {initGardenIdle,stepGardenIdle} from './garden-idle.js';
import {plantCrop,waterCrop,harvestCrop,cookGardenDish} from './garden.js';
export const GARDEN_WORK_TIMING={walk:2.2,work:3,return:1.4};
export function createGardenWorker(state,options={}){
 let task=null;
 return {get task(){return task;},advance(dt,now=Date.now()){
  const a=initGardenIdle(state,now);
  if(!a.enabled){task=null;return null;}
  if(!Number.isFinite(dt)||dt<=0||dt>.25)return null;
  if(!task){
   if(now<a.nextAt)return null;
   const copy=structuredClone({coins:state.coins,garden:state.garden,food:state.food});const plan=stepGardenIdle(copy,now);
   a.day=copy.garden.auto.day;a.spent=copy.garden.auto.spent-(plan?.type==='plant'?plan.crop.seed:0);
   if(!plan){a.nextAt=copy.garden.auto.nextAt;a.message=copy.garden.auto.message;return null;}
   task={...plan,elapsed:0,committed:false,timing:options.timing?.(plan)||GARDEN_WORK_TIMING};a.message={plant:'씨앗을 들고 밭으로 가요.',water:'물뿌리개를 들고 밭으로 가요.',harvest:'바구니를 들고 수확하러 가요.',cook:'수확한 재료로 요리하러 가요.'}[plan.type];return null;
  }
  task.elapsed+=dt;const end=task.timing.walk+task.timing.work;
  if(!task.committed&&task.elapsed>=end){
   task.committed=true;let result;
   if(task.type==='plant'&&a.spent+task.crop.seed<=100&&state.coins-task.crop.seed>=50){result=plantCrop(state,task.plot,task.crop.id,now);if(result)a.spent+=result.seed;}
   if(task.type==='water')result=waterCrop(state,task.plot);
   if(task.type==='harvest')result=harvestCrop(state,task.plot,now);
   if(task.type==='cook')result=cookGardenDish(state,task.dish.id);
   a.nextAt=now+2000;
   if(result){if(task.type==='harvest')task.result=result;a.message=task.message;return {...task};}
   a.message='밭 상태가 바뀌었어요. 다음 일을 찾아요.';
  }
  if(task.elapsed>=end+task.timing.return)task=null;
  return null;
 }};
}
