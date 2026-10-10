import {CROPS,GARDEN_DISHES} from './garden-data.js';
export {CROPS,GARDEN_DISHES};
const count=n=>Number.isSafeInteger(n)&&n>=0?n:0;
export function initGarden(state){
 const g=state.garden||={};g.version=1;g.harvests=count(g.harvests);g.cooked=count(g.cooked);g.ingredients||={};g.discovered=Array.isArray(g.discovered)?g.discovered.filter(id=>CROPS.some(c=>c.id===id)):[];g.recipes=Array.isArray(g.recipes)?g.recipes.filter(id=>GARDEN_DISHES.some(r=>r.id===id)):[];
 g.plots=Array.from({length:3},(_,i)=>{const p=g.plots?.[i];return p&&CROPS.some(c=>c.id===p.crop)&&Number.isFinite(p.plantedAt)&&p.plantedAt>=0?{crop:p.crop,plantedAt:p.plantedAt,watered:p.watered===true}:null;});
 g.plotCount=Math.max(1,Math.min(3,count(g.plotCount)));for(const c of CROPS)g.ingredients[c.id]=count(g.ingredients[c.id]);
 for(const r of GARDEN_DISHES)if(g.discovered.includes(r.crop)&&!g.recipes.includes(r.id))g.recipes.push(r.id);return g;
}
export function cropUnlocked(state,id){const c=CROPS.find(c=>c.id===id);return Boolean(c&&(state.garden.harvests>=c.harvests||state.garden.discovered.includes(id)));}
export function plotStatus(state,index,now=Date.now()){
 const g=state.garden;if(!Number.isFinite(now)||now<0||!Number.isInteger(index)||index<0||index>=g.plotCount)return {stage:'locked'};
 const p=g.plots[index];if(!p)return {stage:'empty'};const crop=CROPS.find(c=>c.id===p.crop),elapsed=Math.max(0,(now-p.plantedAt)/1000),remaining=Math.max(0,Math.ceil(crop.seconds-elapsed));
 return {stage:!p.watered?'thirsty':remaining?'growing':'ready',crop,remaining,progress:Math.min(1,elapsed/crop.seconds)};
}
export function plantCrop(state,index,id,now=Date.now()){
 const crop=CROPS.find(c=>c.id===id);if(!Number.isFinite(now)||now<0||plotStatus(state,index,now).stage!=='empty'||!cropUnlocked(state,id)||state.coins<crop.seed)return false;
 state.coins-=crop.seed;state.garden.plots[index]={crop:id,plantedAt:now,watered:false};return crop;
}
export function waterCrop(state,index){const p=state.garden.plots[index];if(!Number.isInteger(index)||index<0||index>=state.garden.plotCount||!p||p.watered)return false;p.watered=true;return true;}
export function harvestCrop(state,index,now=Date.now()){
 const s=plotStatus(state,index,now);if(s.stage!=='ready')return false;const g=state.garden,first=!g.discovered.includes(s.crop.id);g.plots[index]=null;g.harvests++;g.ingredients[s.crop.id]+=3;if(first)g.discovered.push(s.crop.id);
 const recipes=GARDEN_DISHES.filter(r=>r.crop===s.crop.id&&!g.recipes.includes(r.id));g.recipes.push(...recipes.map(r=>r.id));return {crop:s.crop,amount:3,recipes};
}
export function expandGarden(state){const g=state.garden,next=g.plotCount===1?{harvests:3,price:40}:g.plotCount===2?{harvests:8,price:80}:null;if(!next||g.harvests<next.harvests||state.coins<next.price)return false;state.coins-=next.price;g.plotCount++;return true;}
export function cookGardenDish(state,id){const r=GARDEN_DISHES.find(r=>r.id===id),g=state.garden;if(!r||!g.recipes.includes(id)||g.ingredients[r.crop]<r.amount||!state.food?.stock)return false;g.ingredients[r.crop]-=r.amount;state.food.stock[id]=count(state.food.stock[id])+1;g.cooked++;return r;}
