import {dayKey} from './progression.js';
import {CROPS} from './garden.js';
import {normalizeStyle} from './furniture-style.js';
export const HOME_THEMES=[
 {id:'cozy',name:'포근한 쉼터',items:['sofa','rug','bed','lamp'],coins:60,xp:20},
 {id:'reading',name:'작은 독서방',items:['chair','shelf','clock','lamp'],coins:80,xp:25},
 {id:'music',name:'숲속 음악실',items:['record','turntable','sofa','rug'],coins:100,xp:30},
 {id:'garden',name:'초록빛 다실',items:['plant','table','window_seat','shelf'],coins:90,xp:25}
];
export const DIY_RECIPES=[
 {id:'clock',name:'곰 귀 원목 벽시계',harvests:3,cost:{carrot:3,herb:3},coins:25},
 {id:'shelf',name:'다람쥐 도토리 책장',harvests:5,cost:{carrot:4,herb:4},coins:35},
 {id:'lamp',name:'졸린 곰 리넨 램프',harvests:9,cost:{berry:3,mushroom:2},coins:20}
];
const validCount=n=>Number.isSafeInteger(n)&&n>=0?n:0;
const hash=text=>[...text].reduce((n,c)=>(Math.imul(n,31)+c.charCodeAt(0))>>>0,7);
export function initCozyLife(state,now=Date.now()){
 const c=state.cozy||={};c.version=1;c.layouts=Array.from({length:3},(_,i)=>c.layouts?.[i]||null);c.themes=Array.isArray(c.themes)?c.themes.filter(id=>HOME_THEMES.some(t=>t.id===id)):[];c.crafted=Array.isArray(c.crafted)?c.crafted:[];
 c.market||={};c.market.sold=validCount(c.market.sold);c.market.deliveries=validCount(c.market.deliveries);c.market.sales=Array.isArray(c.market.sales)?c.market.sales.slice(0,20):[];
 const key=dayKey(now);if(c.market.day!==key){c.market.day=key;c.market.bought=[];c.market.claimed=[];c.market.orders=[];}c.market.bought||=[];c.market.claimed||=[];c.market.orders||=[];return c;
}
export function dailyStock(state,catalog,now=Date.now()){
 const c=initCozyLife(state,now),pool=catalog.filter(i=>i.price>0&&!i.species&&!i.signature&&i.id!=='basket');
 pool.sort((a,b)=>a.id.localeCompare(b.id));let seed=hash(c.market.day);for(let i=pool.length-1;i>0;i--){seed=(Math.imul(seed,1664525)+1013904223)>>>0;const j=seed%(i+1);[pool[i],pool[j]]=[pool[j],pool[i]];}return pool.slice(0,4);
}
export function shopPrice(state,item,catalog,now=Date.now()){
 const c=initCozyLife(state,now);return !c.market.bought.includes(item.id)&&dailyStock(state,catalog,now).some(i=>i.id===item.id)?Math.ceil(item.price*.75):item.price;
}
export function purchaseFurniture(state,id,catalog,isOpen,now=Date.now()){
 const item=catalog.find(i=>i.id===id);if(!item||state.owned.includes(id)||!isOpen(item))return false;const price=shopPrice(state,item,catalog,now);if(state.coins<price)return false;
 state.coins-=price;state.owned.push(id);state.cozy.market.bought.push(id);return {item,price};
}
export function furnitureSalePrice(item){return item&&!item.signature?Math.floor((item.price||0)*.4):0;}
export function sellFurniture(state,id,catalog,now=Date.now()){
 const item=catalog.find(i=>i.id===id),price=furnitureSalePrice(item);if(!price||!state.owned.includes(id)||state.furniture.some(f=>f.id===id))return false;
 initCozyLife(state,now);state.owned=state.owned.filter(x=>x!==id);state.coins+=price;recordSale(state,item.name,1,price);return price;
}
function recordSale(state,name,amount,coins){const m=state.cozy.market;m.sold+=amount;m.sales.unshift({name,amount,coins});m.sales=m.sales.slice(0,20);}
export function producePrice(state,id,now=Date.now()){const index=CROPS.findIndex(c=>c.id===id);if(index<0)return 0;initCozyLife(state,now);return Math.ceil([3,5,7,9,11,14][index]*(hash(state.cozy.market.day)%CROPS.length===index?1.5:1));}
export function sellProduce(state,id,amount,now=Date.now()){
 const price=producePrice(state,id,now);if(!price||!Number.isSafeInteger(amount)||amount<1||state.garden.ingredients[id]<amount)return false;state.garden.ingredients[id]-=amount;const coins=price*amount;state.coins+=coins;recordSale(state,CROPS.find(c=>c.id===id).name,amount,coins);return coins;
}
export function dailyOrders(state,now=Date.now()){
 const c=initCozyLife(state,now),pool=CROPS.filter(crop=>state.garden.discovered.includes(crop.id));const start=hash(c.market.day);
 for(let i=0;i<pool.length&&c.market.orders.length<3;i++){const crop=pool[(start+i)%pool.length];if(c.market.orders.some(o=>o.id===crop.id))continue;const slot=c.market.orders.length,amount=3+slot;c.market.orders.push({id:crop.id,name:['복실복실 식당','숲속 찻집','작은 빵집'][slot],amount,coins:producePrice(state,crop.id,now)*amount+10,xp:8+slot*2});}
 return c.market.orders.map(o=>({...o,crop:CROPS.find(crop=>crop.id===o.id),claimed:c.market.claimed.includes(o.id)}));
}
export function deliverOrder(state,id,now=Date.now()){
 const order=dailyOrders(state,now).find(o=>o.id===id);if(!order||order.claimed||state.cozy.market.claimed.length>=3||state.garden.ingredients[id]<order.amount)return false;state.garden.ingredients[id]-=order.amount;state.coins+=order.coins;state.progress.xp+=order.xp;state.cozy.market.claimed.push(id);state.cozy.market.deliveries++;return order;
}
export function themeStatus(state,theme){const placed=new Set(state.furniture.map(f=>f.id));return {count:theme.items.filter(id=>placed.has(id)).length,total:theme.items.length,claimed:state.cozy.themes.includes(theme.id)};}
export function claimTheme(state,id){initCozyLife(state);const theme=HOME_THEMES.find(t=>t.id===id);if(!theme)return false;const status=themeStatus(state,theme);if(status.claimed||status.count<status.total)return false;state.cozy.themes.push(id);state.coins+=theme.coins;state.progress.xp+=theme.xp;return theme;}
export function craftFurniture(state,id){initCozyLife(state);const recipe=DIY_RECIPES.find(r=>r.id===id);if(!recipe||state.owned.includes(id)||state.garden.harvests<recipe.harvests||state.coins<recipe.coins||Object.entries(recipe.cost).some(([id,n])=>state.garden.ingredients[id]<n))return false;for(const [id,n]of Object.entries(recipe.cost))state.garden.ingredients[id]-=n;state.coins-=recipe.coins;state.owned.push(id);if(!state.cozy.crafted.includes(id))state.cozy.crafted.push(id);return recipe;}
export function saveLayout(state,index,catalog){
 initCozyLife(state);if(!Number.isInteger(index)||index<0||index>2)return false;const items=state.furniture.filter(f=>catalog.some(i=>i.id===f.id)&&state.owned.includes(f.id));
 state.cozy.layouts[index]={skin:state.skin,items:structuredClone(items),savedAt:Date.now()};return true;
}
export function restoreLayout(state,index,catalog,isSkinOpen){
 const layout=state.cozy.layouts[index];if(!layout)return false;
 const items=layout.items.filter(f=>state.owned.includes(f.id)&&catalog.some(i=>i.id===f.id&&(!i.species||i.species===state.species))&&Number.isFinite(f.x)&&Number.isFinite(f.y)).map(f=>({...f,x:Math.min(.95,Math.max(.05,f.x)),y:Math.min(.97,Math.max(.2,f.y)),style:normalizeStyle(f.style,f.id)}));
 state.furniture=structuredClone(items);return {skin:isSkinOpen(layout.skin)?layout.skin:state.skin,count:items.length,skipped:layout.items.length-items.length};
}
