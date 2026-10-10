import {CROPS,GARDEN_DISHES,recipesForCrop,cookGardenDish} from './garden.js';
export function createGardenUI(api){
 const {state,openSheet,save,toast,iconHTML,recordEvent,updateUI,log}=api;let selected='all';
 const refresh=()=>{save();updateUI();};
 function navigation(active){const tabs=document.createElement('div');tabs.className='tabs garden-tabs';for(const [label,action] of [['식당 메뉴',()=>api.restaurant()],['텃밭',garden],['우리 주방',kitchen],['우리 냉장고',()=>api.restaurant('우리 냉장고')]]){const b=document.createElement('button');b.textContent=label;b.className=label===active?'active':'';b.onclick=action;tabs.append(b);}return tabs;}
 function garden(crop){api.enterGarden(crop);}
 function updateTimers(){api.updateGarden();}
 function kitchen(crop){
  if(typeof crop==='string'&&(crop==='all'||CROPS.some(c=>c.id===crop)))selected=crop;
  openSheet('우리의 작은 주방','직접 기른 재료로 마음을 담아 만들어요');const content=document.querySelector('#sheet-content');content.className='garden-sheet';content.innerHTML=`<div class="garden-banner">${iconHTML('feed')}<div><b>수확할수록 늘어나는 요리책</b><p>작물을 처음 수확하면 해당 요리법 2개가 열려요. 재료로 만든 요리는 냉장고에 보관돼요.</p></div><span>완성 ${state.garden.cooked}접시</span></div><div class="garden-pantry">${CROPS.map(c=>`<span>${c.name} <b>${state.garden.ingredients[c.id]}개</b></span>`).join('')}</div><div class="food-grid"></div>`;content.prepend(navigation('우리 주방'));
  const filters=document.createElement('div');filters.className='recipe-filters';filters.setAttribute('aria-label','작물별 요리책');
  for(const c of [{id:'all',name:'전체 요리'},...CROPS]){const b=document.createElement('button');b.setAttribute('aria-pressed',String(selected===c.id));b.setAttribute('aria-label',c.id==='all'?'전체 요리 보기':c.name+' 요리 보기');b.innerHTML=(c.art?`<img src="${c.art}" alt="">`:'')+c.name;b.onclick=()=>kitchen(c.id);filters.append(b);}content.querySelector('.food-grid').before(filters);
  if(selected!=='all'){const c=CROPS.find(c=>c.id===selected),note=document.createElement('div');note.className='recipe-crop-note';note.textContent=c.name+' 재배 → 물 주기 → 첫 수확 → '+recipesForCrop(c.id).map(r=>r.name.replace('텃밭 ','')).join(' · ')+' 해금';filters.after(note);}
  for(const r of (selected==='all'?GARDEN_DISHES:recipesForCrop(selected))){const open=state.garden.recipes.includes(r.id),crop=CROPS.find(c=>c.id===r.crop),have=state.garden.ingredients[r.crop],card=document.createElement('article');card.className='food-card'+(open?'':' locked');card.innerHTML=`<div class="food-art"><img src="${r.icon}" alt="${r.name}"></div><b>${r.name}</b><p>${r.description}</p><div class="food-effects">${iconHTML('feed')} +${r.hunger} ${iconHTML('pet')} +${r.happy} ${iconHTML('sleep')} +${r.energy}</div><small>${open?crop.name+' '+have+'/'+r.amount+'개 · 냉장고 '+(state.food.stock[r.id]||0)+'접시':crop.name+' 첫 수확으로 요리법 해금'}</small><button ${open&&have<r.amount?'disabled':''}>${!open?crop.name+' 재배하러 가기':have<r.amount?'재료를 수확해 주세요':'한 접시 만들기'}</button>`;card.querySelector('button').setAttribute('aria-label',open?r.name+' 만들기':crop.name+' 재배하러 가기');card.querySelector('button').onclick=()=>{if(!open){garden(r.crop);return;}const made=cookGardenDish(state,r.id);if(!made)return;recordEvent(state,'cook');log(made.name+' 한 접시를 만들었어요.');refresh();kitchen(selected);toast('정성 가득한 '+made.name+'가 냉장고에 들어갔어요!');};content.querySelector('.food-grid').append(card);}
 }
 return {garden,kitchen,updateTimers,navigation};
}
