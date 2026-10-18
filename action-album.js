// Adapted from the installed 16-species v1 action album (2026-10-14).
// Preview state is local: never awards care, changes outfits, or changes growth.
import {resolveAnimation} from './animation-player.js';
import {growthInfo} from './desktop-features.js';
import {SOFT_BEHAVIORS,behaviorRequirement} from './soft-actions.js';

export const SOFT_ALBUM_ACTIONS=[
 ['idle','일상','편안한 대기','쉬는 동안 보여요.','', 'sleep'],
 ['walk','일상','산책','방 바닥을 누르거나 가구로 갈 때 걸어요.','', 'move'],
 ...SOFT_BEHAVIORS.map(a=>[a.id,['run','jump','stumble','peek'].includes(a.id)?'일상':['roll','fly','fight'].includes(a.id)?'모험·놀이':'작은 일상',a.title,'다양한 행동에서 고르면 실제 방에서 함께해요. 쉬는 동안 스스로 보여주기도 해요.','',a.icon]),
 ['pet','교감','기분 좋은 반응','쓰다듬으면 기뻐해요.','', 'pet'],
 ['carry','교감','살짝 들기','친구를 길게 누르고 끌어 올려요.','', 'pet'],
 ['struggle','교감','내려 주세요','안고 약 2초가 지나면 버둥거려요.','', 'pet'],
 ['landing','교감','사뿐 착지','친구를 바닥에 내려놓아요.','', 'move'],
 ['dizzy','교감','해롱해롱','높은 곳에서 내려온 뒤 잠시 어지러워해요.','', 'flower'],
 ['recover','교감','몸 추스리기','착지와 어지럼 뒤 다시 일어나요.','', 'pet'],
 ['eat','식사·휴식','오물오물 식사','식탁에 차린 요리를 톡 눌러요.','table', 'feed'],
 ['sleep','식사·휴식','꾸벅꾸벅','쉬기에서 잠깐 눈을 붙여요.','', 'sleep'],
 ['sofa','가구·놀이','소파에 앉기','소파에 다가가 앉고 다시 내려와요.','sofa', 'decorate'],
 ['home-nap','가구·놀이','침대 낮잠','침대를 놓고 함께 쉬어요.','bed', 'sleep'],
 ['home-bath','가구·놀이','거품 목욕','욕조를 놓고 목욕해요.','bathtub', 'clean'],
 ['play','가구·놀이','당근 인형 안기','인형을 안았다가 제자리에 돌려놓아요.','toy_plush', 'play'],
 ['home-read','가구·놀이','책장 곁 독서','책장을 눌러 책을 읽어요.','shelf', 'journal'],
 ['home-climb','가구·놀이','사다리 타고 책 꺼내기','벽 책장까지 사다리를 타고 오르내려요.','wall_shelf', 'journal'],
 ['sofa-enter','가구·놀이','소파에 앉는 순간','소파 사용 시작과 끝에 이어져요.','sofa', 'decorate'],
 ['bed-enter','가구·놀이','침대에 눕는 순간','침대 사용 시작과 끝에 이어져요.','bed', 'sleep'],
 ['bath-enter','가구·놀이','욕조에 들어가기','목욕 시작과 끝에 이어져요.','bathtub', 'clean'],
 ['play-enter','가구·놀이','놀이 준비','놀이의 시작과 끝에 이어져요.','toy_plush', 'play']
].map(([id,category,title,trigger,furniture,icon])=>({id,category,title,trigger,furniture,icon}));

export const ALBUM_ACTIONS=[
 ['idle','일상','편안한 대기','아무것도 하지 않고 잠시 쉬고 있을 때예요.','', 'sleep'],
 ['walk','일상','산책 · 깡총걸음','방 바닥을 톡 누르거나 친구가 스스로 산책할 때 볼 수 있어요.','', 'move'],
 ['look','일상','주변 둘러보기','생활 메뉴의 작은 몸짓에서 성격에 따라 주변을 살펴봐요. 도감에서는 언제든 볼 수 있어요.','', 'flower'],
 ['stretch','일상','기지개','성체 곰의 작은 몸짓에서 만나요. 다른 친구의 기지개는 도감에서 미리 볼 수 있어요.','', 'sun'],
 ['pet','교감','기분 좋은 반응','친구를 짧게 누르거나 쓰담쓰담을 눌러 주세요.','', 'pet'],
 ['carry','교감','살짝 들기','친구를 길게 누른 채 끌면 안아 올려요. 손을 떼면 내려놓아요.','', 'pet'],
 ['struggle','교감','내려 주세요','안아 올린 채 약 2초가 지나면 버둥거려요.','', 'pet'],
 ['eat','식사·휴식','냠냠 식사','음식에서 요리를 준비한 뒤 식사 테이블의 음식을 눌러 주세요.','table', 'feed'],
 ['drink','식사·휴식','물 한 모금','설정에서 물컵을 꺼내고 방의 물컵을 톡 눌러 주세요.','water', 'clean'],
 ['sleep','식사·휴식','꾸벅꾸벅','쉬기를 누르면 잠들어요. 침대에서도 쉴 수 있어요.','', 'sleep'],
 ['sofa','가구·놀이','소파에서 쉬기','소파를 눌러 친구가 다가와 쉬도록 해 주세요.','sofa', 'decorate'],
 ['read','가구·놀이','책 읽는 시간','책장을 배치하고 톡 눌러 함께 책을 읽어요.','shelf', 'journal'],
 ['music','가구·놀이','음악에 귀 기울이기','음악 가구를 배치하고 누르면 리듬을 즐겨요.','record', 'sound-on'],
 ['play','가구·놀이','러그에서 놀기','러그를 배치한 뒤 함께 놀기의 러그 놀이를 골라요.','rug', 'play'],
 ['stumble','깜짝 행동','앗, 꽈당!','산책 중 가끔 발이 꼬여요. 식사나 가구 이용 중에는 방해하지 않아요.','', 'flower'],
 ['sneeze','깜짝 행동','에취!','쉬는 동안 가끔 재채기해요. 연달아 반복하지 않아요.','', 'flower']
].map(([id,category,title,trigger,furniture,icon])=>({id,category,title,trigger,furniture,icon}));
export const ALBUM_CATEGORIES=['전체',...new Set(ALBUM_ACTIONS.map(a=>a.category))];
const BANKS={carry:'hold-pickup',sofa:'home-rest',read:'home-read',music:'home-music',play:'home-play'};
export function albumPose(action,elapsed=0){
 const bank=BANKS[action.id]||action.id;
 return {bank,elapsed,...(action.id==='carry'?{progress:Math.min(1,elapsed/.28)}:{})};
}
export function albumPreview(catalog,species,age,look,action){
 const previewLook={...(age==='baby'?{style:'none',color:0}:look),previewAge:age};
 const resolved=resolveAnimation(catalog,species,age,previewLook,albumPose(action));
 return {look:previewLook,resolved,supported:Boolean(resolved?.supported)};
}
export function albumRequirement(state,action,catalog,isOpen,condition){
 if(!action.furniture)return {text:'처음부터 함께해요',label:'',item:null,open:true};
 const item=catalog.find(i=>i.id===action.furniture);
 if(!item)return {text:'이 가구는 아직 준비 중이에요.',label:'',item:null,open:false};
 const open=isOpen(item),placed=state.furniture.some(f=>f.id===item.id),owned=state.owned.includes(item.id);
 return {item,open,placed,text:item.name+' · '+(placed?'방에 놓여 있어요':owned?'수납함에 있어요':open?'구입·배치 가능':condition(item)),label:placed?'가구 배치 보기':owned?'수납함에서 꺼내기':open?'가구 준비하기':'해금 조건 보기'};
}

export function createActionAlbum(api){return function openAlbum(){
 const {state,openSheet,drawPet,iconHTML,animationCatalog}=api;
 const soft=animationCatalog.skin==='soft-roster-v2',actions=soft?SOFT_ALBUM_ACTIONS:ALBUM_ACTIONS,categories=['전체',...new Set(actions.map(a=>a.category))];
 openSheet('친구의 행동 도감','작은 몸짓을 발견하는 시간');
 const content=document.querySelector('#sheet-content');content.className='action-album-sheet';
 content.innerHTML=`<div class="album-navigation"></div><div class="album-filters" aria-label="행동 분류"></div><div class="action-book"><section class="action-preview"><div class="album-ages" aria-label="미리보기 나이"></div><canvas width="320" height="280" aria-label="친구 행동 미리보기"></canvas><div class="album-controls"><button class="pill album-pause">일시 정지</button><button class="pill album-flip">방향 바꾸기</button></div><p class="album-preview-note"></p></section><section class="action-pages"><div class="album-actions" aria-label="행동 선택"></div><article class="album-detail" aria-live="polite"><h3></h3><p class="album-trigger"></p><p class="album-requirement"></p><button class="pill album-furniture"></button></article></section></div><p class="album-footnote">미리보기로 실제 나이·옷차림이 바뀌거나 성장·돌봄 보상을 받지는 않아요. 플레이 시간에 따른 해금은 계속 진행돼요.</p><button class="pill album-extras">더 많은 몸짓 보기</button>`;
 content.querySelector('.album-navigation').append(api.tabs('몸짓 도감'));
 const root=content.querySelector('.action-book'),canvas=root.querySelector('canvas'),ctx=canvas.getContext('2d');
 const look={...(state.desktop.outfits[state.species]||{style:'none',color:0})};
 let selected=actions[0],category='전체',age=growthInfo(state).stage==='baby'?'baby':'adult',paused=false,direction=1,elapsed=0,last=null;
 const ageRail=root.querySelector('.album-ages'),filter=content.querySelector('.album-filters'),list=root.querySelector('.album-actions');
 function button(text,fn){const b=document.createElement('button');b.type='button';b.textContent=text;b.onclick=fn;return b;}
 function detail(){
  const preview=albumPreview(animationCatalog,state.species,age,look,selected),req=albumRequirement(state,selected,api.catalog,api.isFurnitureOpen,api.furnitureCondition);
  root.querySelector('h3').textContent=selected.title;root.querySelector('.album-trigger').textContent=selected.trigger;
  root.querySelector('.album-requirement').textContent=req.text;
  const behavior=SOFT_BEHAVIORS.find(a=>a.id===selected.id),lock=behaviorRequirement(state,selected.id);
  if(soft&&behavior)root.querySelector('.album-requirement').textContent=lock.text;
  let execute=root.querySelector('.album-execute');if(!execute){execute=button('방에서 함께하기',()=>{if(api.startBehavior(selected.id))api.closeSheet();});execute.className='pill album-execute';root.querySelector('.album-detail').append(execute);}
  execute.hidden=!soft||!behavior;execute.disabled=!lock.open;
  const link=root.querySelector('.album-furniture');link.hidden=!req.item;link.textContent=req.label;link.onclick=()=>api.openFurniture(req.item.id);
  root.querySelector('.album-preview-note').textContent=age==='baby'?'아기 · 원래 모습':animationCatalog.skin!=='soft-roster-v2'&&look.style&&look.style!=='none'?'성체 · 현재 옷차림':'성체 · 원래 모습';
  if(!preview.supported)root.querySelector('.album-preview-note').textContent+=' · 이 모습의 전용 동작은 준비 중이라 대기 모습으로 보여요.';
  for(const b of ageRail.children)b.setAttribute('aria-pressed',String(b.dataset.age===age));
 }
 function renderList(){
  list.replaceChildren();for(const a of actions.filter(a=>category==='전체'||a.category===category)){
   const b=button('',()=>{selected=a;elapsed=0;last=null;renderList();detail();});
   b.innerHTML=(a.id==='drink'?'<img class="ui-art" src="assets/thin-home-v3/water-cup.webp" alt="">':iconHTML(a.icon))+`<span>${a.title}</span>`;b.setAttribute('aria-pressed',String(selected.id===a.id));list.append(b);
  }
  for(const b of filter.children)b.setAttribute('aria-pressed',String(b.textContent===category));
 }
 for(const c of categories)filter.append(button(c,()=>{category=c;if(c!=='전체'&&selected.category!==c)selected=actions.find(a=>a.category===c);elapsed=0;last=null;renderList();detail();}));
 for(const [id,label] of [['baby','아기'],['adult','성체']]){const b=button(label,()=>{age=id;elapsed=0;last=null;detail();});b.dataset.age=id;ageRail.append(b);}
 const pause=root.querySelector('.album-pause');pause.setAttribute('aria-pressed','false');pause.onclick=()=>{paused=!paused;last=null;pause.textContent=paused?'다시 재생':'일시 정지';pause.setAttribute('aria-pressed',String(paused));};
 root.querySelector('.album-flip').onclick=()=>{direction*=-1;};
 content.querySelector('.album-extras').onclick=api.extras;
 renderList();detail();
 function animate(ms){
  if(!root.isConnected)return;
  if(!paused&&!document.hidden&&last!==null)elapsed+=Math.min(.1,(ms-last)/1000);last=ms;
  const p=albumPreview(animationCatalog,state.species,age,look,selected),pose=albumPose(selected,elapsed);
  pose.duration=p.resolved?.spec.duration||4.8;
  ctx.clearRect(0,0,320,280);drawPet(ctx,160,245,246,state.species,elapsed,false,direction,null,p.look,pose);
  requestAnimationFrame(animate);
 }
 requestAnimationFrame(animate);
};}
