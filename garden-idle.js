import {CROPS,GARDEN_DISHES,cropUnlocked,plotStatus,plantCrop,waterCrop,harvestCrop,cookGardenDish} from './garden.js';
const day=now=>new Date(now+9*3600000).toISOString().slice(0,10);
export function initGardenIdle(state,now=Date.now()){
 const a=state.garden.auto||={};a.enabled=a.enabled!==false;a.day||=day(now);a.spent=Number.isSafeInteger(a.spent)&&a.spent>=0?a.spent:0;a.nextAt=Number.isFinite(a.nextAt)?a.nextAt:0;a.message||='펫이 텃밭과 주방을 돌보고 있어요.';return a;
}
// One action per visible game tick; never replay suspended or closed-app time.
export function stepGardenIdle(state,now=Date.now()){
 if(!Number.isFinite(now)||now<0)return null;const g=state.garden,a=initGardenIdle(state,now);
 if(a.day!==day(now)){a.day=day(now);a.spent=0;}
 if(!a.enabled||now<a.nextAt)return null;a.nextAt=now+2000;
 const done=(type,message,data={})=>{a.message=message;return {type,message,...data};};
 for(let i=0;i<g.plotCount;i++)if(plotStatus(state,i,now).stage==='ready'){const result=harvestCrop(state,i,now);return done('harvest',result.crop.name+' 3개 자동 수확'+(result.recipes.length?' · 요리법 '+result.recipes.length+'종 해금':''),{result,plot:i});}
 for(let i=0;i<g.plotCount;i++)if(plotStatus(state,i,now).stage==='thirsty'){waterCrop(state,i);return done('water',plotStatus(state,i,now).crop.name+'에 자동으로 물을 줬어요.',{plot:i});}
 const total=GARDEN_DISHES.reduce((n,r)=>n+(state.food.stock[r.id]||0),0);
 if(total<24){const recipes=GARDEN_DISHES.filter(r=>g.recipes.includes(r.id)&&g.ingredients[r.crop]>=r.amount&&(state.food.stock[r.id]||0)<3).sort((x,y)=>(state.food.stock[x.id]||0)-(state.food.stock[y.id]||0));
  if(recipes.length){const dish=cookGardenDish(state,recipes[0].id);return done('cook',dish.name+' 자동 완성 · 냉장고에 보관',{dish});}}
 for(let i=0;i<g.plotCount;i++)if(plotStatus(state,i,now).stage==='empty'){
  const planted=new Set(g.plots.filter(Boolean).map(p=>p.crop));
  const available=CROPS.filter(c=>cropUnlocked(state,c.id)&&g.ingredients[c.id]<12).sort((x,y)=>Number(g.discovered.includes(x.id))-Number(g.discovered.includes(y.id))||Number(planted.has(x.id))-Number(planted.has(y.id))||g.ingredients[x.id]-g.ingredients[y.id]||y.harvests-x.harvests);
  const crop=available.find(c=>a.spent+c.seed<=100&&state.coins-c.seed>=50);
  if(crop){plantCrop(state,i,crop.id,now);a.spent+=crop.seed;return done('plant',crop.name+' 씨앗 자동 심기 · '+crop.seed+' 도토리',{crop,plot:i});}
 }
 a.message=total>=24?'냉장고가 든든해요. 요리를 먹으면 다시 만들어요.':a.spent>=97?'오늘 씨앗 예산을 다 썼어요. 내일 다시 심어요.':state.coins<54?'도토리 50개를 남겨 두고 재배를 쉬어요.':'작물이 자라기를 기다리고 있어요.';
 return null;
}
