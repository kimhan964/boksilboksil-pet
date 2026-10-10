import {createGardenSpace} from './garden-space.js';
import {initGarden} from './garden.js';
import {createGardenUI} from './garden-ui.js';
import {furnitureAsset,visibleFurniture,sourceUnlocked,sourceCondition,nextDelivery,furnitureDepth} from './current-settings.js';
import {createSettingsUI} from './settings-ui.js';
import {resolveAnimation,animationFrame,holdPose,lifeKind,motionStyle} from './animation-player.js';
import {REACTION_EVENTS,PLAY_WORDS} from './reaction-data.js';
import {expressionDuration,expressionPose} from './expression-motion.js';
import {hopPhase,hopLift,hopTravelRate} from './rabbit-hop.js';
import {FOODS,initFood,isFoodUnlocked,refreshFoodUnlocks,foodCondition,buyFood,eatFood,favoriteKnown} from './food.js';
import {DESKTOP_FURNITURE,LIFE,TOYS,initDesktop,growthInfo,completeDesktopActivity,refreshDesktop,desktopUnlocked,desktopCondition} from './desktop-features.js';
import {HABITS} from './habits-data.js';
import {furnitureImage} from './furniture-style.js';
import {createDesktopUI} from './desktop-game-ui.js';
import {GOALS,DAILY_GOALS,SKIN_LEVELS,FURNITURE_LEVELS,PERIODS,TIME_UNLOCKS,timePeriod,formatPlayTime,unlockCondition,refreshUnlocks,addPlayTime,initProgress,refreshDay,dayKey,levelInfo,level,isUnlocked,recordEvent,goalStatus,claimGoal} from './progression.js';
import {SKINS,findSkin} from './skins.js';
import {UI_ICONS,iconHTML} from './ui-icons.js';
const $=s=>document.querySelector(s);
const SPECIES=[['rabbit','토끼','모루'],['otter','수달','보리'],['squirrel','다람쥐','도토'],['hedgehog','고슴도치','밤이'],['raccoon','너구리','누리'],['fox','여우','솔'],['bear','곰','두리'],['owl','부엉이','달'],['cat','고양이','치즈'],['puppy','강아지','쿠키'],['hamster','햄스터','콩이'],['panda','판다','포포'],['red_panda','레서판다','단풍'],['lamb','아기 양','몽실'],['koala','코알라','코코'],['penguin','펭귄','빙글']];
const CATALOG=[
  {id:'sofa',name:'토끼 귀 미니 소파',price:0,cat:'가구',w:.27},
  {id:'table',name:'고양이 발 미니 식탁',price:0,cat:'가구',w:.17},
  {id:'rug',name:'포근한 발바닥 놀이 러그',price:0,cat:'소품',w:.30},
  {id:'plant',name:'잎새 세라믹 화분대',price:80,cat:'소품',w:.13},
  {id:'lamp',name:'졸린 곰 리넨 램프',price:70,cat:'소품',w:.10},
  {id:'shelf',name:'다람쥐 도토리 책장',price:120,cat:'가구',w:.18},
  {id:'bed',name:'발바닥 리넨 데이베드',price:140,cat:'가구',w:.27},
  {id:'chair',name:'여우 꼬리 독서 의자',price:100,cat:'가구',w:.16},
  {id:'aquarium',name:'작은 물고기 수조장',price:160,cat:'소품',w:.16},
  {id:'clock',name:'곰 귀 원목 벽시계',price:60,cat:'벽 장식',w:.09,wall:true},
  {id:'tv',name:'고양이 원목 TV장',price:150,cat:'가구',w:.17},
  {id:'record',name:'곰 음악 장식장',price:90,cat:'소품',w:.13}
  ,...DESKTOP_FURNITURE
  ,{id:'basket',name:'숨은 간식 바구니',price:25,cat:'놀이감',w:.12,file:'desktop/basket.webp',activity:'explore'}
];
const STORE='boksil-mobile-landscape-v1';
const initial=()=>({version:1,species:'rabbit',coins:350,bond:0,created:Date.now(),updated:Date.now(),stats:{hunger:80,happy:85,clean:90,energy:90},petStats:{},owned:['sofa','table','rug','plant'],furniture:[{id:'sofa',x:.24,y:.66},{id:'rug',x:.54,y:.85},{id:'table',x:.73,y:.77},{id:'plant',x:.88,y:.57}],journal:[{at:Date.now(),text:'모루와 숲속의 작은 집에 이사 왔어요. 우리의 첫 번째 하루!'}],daily:{}});
let state=initial(),hadSave=false;
try{const saved=JSON.parse(localStorage.getItem(STORE));if(saved?.version===1&&SPECIES.some(s=>s[0]===saved.species)&&Array.isArray(saved.furniture)){state={...state,...saved};hadSave=true;}}catch{}
// Preserve the existing companion when migrating a multi-pet save.
state.singleCompanion=true;
state.companionId=SPECIES.some(s=>s[0]===state.companionId)?state.companionId:state.species;
state.species=state.companionId;
state.skin=findSkin(state.skin).id;
initProgress(state);initGarden(state);initFood(state);initDesktop(state,hadSave);
// Time away affects needs gently, capped so returning remains welcoming.
const away=Math.min(8,Math.max(0,(Date.now()-state.updated)/3600000));
for(const [key,rate]of Object.entries({hunger:3,happy:1,clean:2,energy:1,hydration:3}))state.stats[key]=Math.max(20,state.stats[key]-away*rate);
const animationCatalog=await fetch('assets/animations/catalog.json').then(r=>r.json());
const animationMetadata=new Map();for(const group of [animationCatalog.costumes,animationCatalog.base])for(const species of Object.values(group))for(const banks of Object.values(species))for(const spec of Object.values(banks))animationMetadata.set(spec.file,{size:spec.size,offset:spec.offset,frames:spec.count});
const imageCache=new Map(),atlasCache=new Map();
function image(file){if(!imageCache.has(file)){const img=new Image();img.src='assets/'+file;imageCache.set(file,img);}return imageCache.get(file);}
function atlas(file){if(atlasCache.has(file)){const img=atlasCache.get(file);atlasCache.delete(file);atlasCache.set(file,img);return img;}const img=image(file);if(!img.complete||!img.naturalWidth)return null;if(atlasCache.size>=6){const old=atlasCache.keys().next().value;atlasCache.get(old).src='';atlasCache.delete(old);imageCache.delete(old);}
 atlasCache.set(file,img);return img;}
for(const item of CATALOG.filter(i=>visibleFurniture(i,state.species)))image(item.file||item.id+'.webp');
for(const name of UI_ICONS)image('ui-icons/'+name+'.png');
// Current catalog is the sole source for every character image.
let background=image(findSkin(state.skin).file);
const room=$('#room'),ctx=room.getContext('2d');
let arrangementChanged=false;
let width=1,height=1,dpr=1,edit=false,selected=null,drag=null,animTime=0,last=0,toastTimer,audio=null,sound=state.desktop.settings.sound;
let pet={x:.51,y:.77,target:null,until:3,action:null,dir:1};
let particles=[],toySession=null,toyDrag=null,followMode=false,followMoved=0,followStart=null,heldPet=null;
const desktopUI=createDesktopUI({state,image,iconHTML,drawPet,openSheet,closeSheet,toast,log,save,updateUI,care,startToy,setFollow,beginLife,canAct,beginHabit,animationCatalog,catalog:CATALOG,activityFor,shop,recordPurchase:()=>recordEvent(state,'buy'),furnitureImage,furnitureFile,onFurnitureStyle:()=>{arrangementChanged=true;}});
const gardenSpace=createGardenSpace({state,save,toast,recordEvent,updateUI,log,iconHTML,closeSheet,drawPet,kitchen:crop=>gardenUI.kitchen(crop),prepare:()=>{if(edit||pet.action&&!pet.action.automatic){toast('하던 돌봄이나 꾸미기를 마친 뒤 텃밭으로 가요.');return false;}cancelInteraction();pet.action=null;pet.target=null;return true;},onHome:()=>{closeSheet();pet.until=animTime+3;roomCaption();resize();}});
const gardenUI=createGardenUI({state,openSheet,save,toast,iconHTML,recordEvent,updateUI,log,restaurant,enterGarden:crop=>gardenSpace.enter(crop),updateGarden:()=>gardenSpace.update()});
function canAct(){return !edit&&(!pet.action||pet.action.automatic)&&!heldPet;}
function interruptAutonomy(){if(pet.action?.automatic){pet.action=null;pet.words=null;pet.target=null;pet.until=animTime+5;}}
function furnitureOpen(item){return sourceUnlocked(state,item)||state.owned.includes(item.id)||(item.id==='basket'?state.desktop.counts.play>=1||state.progress.playSeconds>=120:DESKTOP_FURNITURE.some(i=>i.id===item.id)?desktopUnlocked(state,item):isUnlocked(state,'furniture',item.id));}
function furnitureCondition(item){const source=sourceCondition(state,item);return source&&!item.signature?source+' 또는 '+(Number.isFinite(item.minutes)?'플레이 '+item.minutes+'분':unlockCondition(state,'furniture',item.id)):(item.id==='basket'?'함께 놀기 1회 또는 플레이 2분':DESKTOP_FURNITURE.some(i=>i.id===item.id)?desktopCondition(state,item):unlockCondition(state,'furniture',item.id));}
function activityFor(id){return DESKTOP_FURNITURE.find(i=>i.id===id)?.activity||({table:'tea',clock:'clock',plant:'nature',sofa:'rest',bed:'rest',chair:'read',shelf:'read',lamp:'rest',record:'music',aquarium:'fish',tv:'watch'}[id]);}
function setFollow(on){if(gardenSpace.active)gardenSpace.home();if(on&&!canAct())return toast('친구가 하던 일을 마칠 때까지 기다려 주세요.');interruptAutonomy();followMode=on;followMoved=0;followStart=null;toast(on?'방 바닥을 누른 채 움직여요. 산책을 마치려면 손가락을 떼세요.':'산책을 마쳤어요.');}
function beginLife(id,automatic=false){if(gardenSpace.active)gardenSpace.home();if(!canAct())return toast('친구가 하던 일을 마칠 때까지 기다려 주세요.');const f=state.furniture.find(i=>i.id===id&&visibleFurniture(CATALOG.find(c=>c.id===id),state.species)),activity=activityFor(id);if(!f||!LIFE[activity])return;followMode=false;const kind=lifeKind(id,activity);pet.action={type:'life',activity,kind,automatic,elapsed:0,duration:animationCatalog.durations[kind],remaining:null};pet.target=floorTarget(f.x,f.y+.04);if(!automatic)toast(name()+'와 '+LIFE[activity].name+' 시간이에요.');}
function finishLife(){const activity=pet.action.activity,data=LIFE[activity];for(const key of ['happy','energy','clean'])if(data[key])state.stats[key]=clamp(state.stats[key]+data[key],0,100);if(['tea','drink'].includes(activity))state.stats.hydration=clamp(state.stats.hydration+(activity==='drink'?40:25),0,100);completeDesktopActivity(state,activity);recordEvent(state,activity);pet.action=null;pet.until=animTime+6;burst(data.icon);log(name()+'와 '+data.name+' 시간을 보냈어요.');updateUI();toast('포근한 '+data.name+' · 조금 더 친해졌어요.');showReaction(({drink:'water',rest:'rest',nature:'garden',explore:'toy',fish:'rest',clock:'rest',watch:'rest'})[activity]||activity);}
function beginHabit(automatic=false){if(gardenSpace.active)gardenSpace.home();if(!canAct())return toast('친구가 하던 일을 마칠 때까지 기다려 주세요.');interruptAutonomy();const info=HABITS[state.species],baby=growthInfo(state).stage==='baby';pet.target=null;pet.action={type:'habit',automatic,pose:baby?(['rabbit','puppy','penguin'].includes(state.species)?'jump':'look'):({rabbit:'jump',otter:'pet',squirrel:'sniff',hedgehog:'rest',raccoon:'rub',fox:'jump',bear:'stretch',owl:'look'}[state.species]||'look'),remaining:info.seconds};if(!automatic)toast(name()+'의 '+(baby?'작은 몸짓':info.name)+'을 함께 봐요.');}
function finishHabit(){if(!pet.action.automatic){state.stats.happy=clamp(state.stats.happy+8,0,100);completeDesktopActivity(state,'personality');recordEvent(state,'personality');const earned=reward('personality',6);log(name()+'의 작은 몸짓을 함께 관찰했어요.');toast('우리 친구의 취향을 알아가요.'+(earned?' +'+earned+' 도토리':''));updateUI();}pet.action=null;pet.until=animTime+5;}
const reactionAllowed=new Map();function showReaction(event){const data=REACTION_EVENTS[event];if(!data||animTime<(reactionAllowed.get(event)||0))return;reactionAllowed.set(event,animTime+(data.cooldown||3));const duration=expressionDuration(SPECIES.findIndex(i=>i[0]===state.species),data.kind);const words=event==='toy'?PLAY_WORDS[SPECIES.findIndex(i=>i[0]===state.species)]:data.words[0];pet.target=null;pet.action={type:'expression',automatic:true,emotion:data.kind,event,strength:data.strength,elapsed:0,remaining:duration,duration};pet.words=words;pet.until=animTime+5;}
function startToy(id,direction=1){if(gardenSpace.active)gardenSpace.home();if(!canAct())return toast('친구가 하던 일을 마칠 때까지 기다려 주세요.');const toy=TOYS.find(t=>t.id===id);if(!toy||(!['acorn'].includes(id)&&!state.owned.includes(id)))return;followMode=false;let f=state.furniture.find(i=>i.id===id);if(!f){f={id,x:clamp(pet.x+.14,.17,.83),y:.85};state.furniture.push(f);if(!state.owned.includes(id))state.owned.push(id);save();}toySession={id,phase:'approach',round:0,clock:0,direction};pet.action={type:'play',toy:id,remaining:null};pet.target=floorTarget(f.x-.06,f.y+.025);toast(toy.name+'와 함께 놀아요!');}
function advanceToy(dt){if(!toySession||!pet.action?.toy)return;const f=state.furniture.find(i=>i.id===toySession.id);if(!f){toySession=null;pet.action=null;return;}const t=toySession;t.clock+=dt;if(t.phase==='approach'&&!pet.target){t.phase='inspect';t.clock=0;}else if(t.phase==='inspect'&&!pet.target&&t.clock>.7){if(t.id==='acorn'||t.round>=2){toySession=null;finishCare('play');return;}t.round++;t.clock=0;t.phase='follow';t.start=f.x;const next=clamp(f.x+t.direction*(t.id==='toy_mouse'?.15:.12),.16,.84);if(Math.abs(next-f.x)<.04)t.direction*=-1;t.goal=clamp(f.x+t.direction*(t.id==='toy_mouse'?.15:.12),.16,.84);pet.target=floorTarget(t.goal-t.direction*.05,f.y+.025);}else if(t.phase==='follow'){const before=f.x;f.x=t.start+(t.goal-t.start)*Math.min(1,t.clock/.85);if(t.id==='toy_ball')f.roll=(f.roll||0)+(f.x-before)*width/Math.max(10,width*.035);if(t.clock>=.85&&!pet.target){f.x=t.goal;t.phase='inspect';t.clock=0;t.direction*=-1;save();}}}
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function save(){state.updated=Date.now();try{localStorage.setItem(STORE,JSON.stringify(state));$('#save-status span').textContent='자동 저장';}catch{$('#save-status span').textContent='저장 공간을 확인해 주세요';}}
function log(text){state.journal.unshift({at:Date.now(),text});state.journal=state.journal.slice(0,80);save();}
function name(){return SPECIES.find(s=>s[0]===state.species)[2];}
function toast(text){$('#toast').textContent=text;$('#toast').classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('#toast').classList.remove('show'),2500);}
function tone(){if(!sound)return;try{audio||=new(window.AudioContext||window.webkitAudioContext)();audio.resume();const osc=audio.createOscillator(),gain=audio.createGain();osc.type='sine';osc.frequency.setValueAtTime(523,audio.currentTime);osc.frequency.exponentialRampToValueAtTime(784,audio.currentTime+.13);gain.gain.setValueAtTime(.045,audio.currentTime);gain.gain.exponentialRampToValueAtTime(.001,audio.currentTime+.3);osc.connect(gain);gain.connect(audio.destination);osc.start();osc.stop(audio.currentTime+.32);}catch{}}
function updateUI(){refreshDay(state);refreshUnlocks(state);refreshFoodUnlocks(state);refreshDesktop(state);const s=SPECIES.find(s=>s[0]===state.species);$('#pet-name').textContent=s[2];$('#pet-species').textContent=s[1]+' · '+growthInfo(state).name;$('#coins').textContent=state.coins.toLocaleString('ko-KR');$('#bond').textContent='교감 '+state.bond;$('#level').textContent='Lv. '+level(state);updateProgressUI();for(const key of Object.keys(state.stats)){const value=Math.round(state.stats[key]);$('#'+key).value=value;$('#'+key+'-text').textContent=value;}$('.day-count').textContent='함께한 '+(1+Math.floor((Date.now()-state.created)/86400000))+'일째';$('#mood').textContent=state.stats.hunger<35?'배가 조금 고파요.':state.stats.energy<35?'포근하게 쉬고 싶어요.':state.stats.clean<35?'뽀송하게 씻고 싶어요.':'오늘도 함께라서 좋아요.';}

function announceLevel(before){if(level(state)>before){toast('Lv. '+level(state)+'! 새로운 가구와 집 스킨이 열렸어요.');log('우리 집이 Lv. '+level(state)+'로 자랐어요.');}}
function updateProgressUI(){
  $('#play-time').textContent='플레이 '+formatPlayTime(state.progress.playSeconds);$('#time-of-day').textContent=timePeriod().name+'의 작은 집';const info=levelInfo(state.progress.xp);$('#xp-fill').style.width=(info.max?100:info.earned/info.needed*100)+'%';$('#xp-label').textContent=info.max?'포근한 집 마스터':info.earned+' / '+info.needed+' XP';
  const all=[...DAILY_GOALS.map(g=>({...g,daily:true})),...GOALS];const ready=all.filter(g=>{const s=goalStatus(state,g,g.daily);return s.ready&&!s.claimed;});
  const next=ready[0]||all.find(g=>!goalStatus(state,g,g.daily).claimed);$('#goal-badge').textContent=ready.length||'';$('#goals small').textContent=ready.length?'받을 선물 '+ready.length+'개':'오늘의 작은 약속';
  if(next){const status=goalStatus(state,next,next.daily);$('#goal-peek').innerHTML=iconHTML(status.ready?'gift':next.icon)+'<div><small>'+(status.ready?'선물이 도착했어요':next.daily?'오늘의 목표':'성장 목표')+'</small><b>'+next.title+'</b><span>'+status.value+' / '+next.target+' · '+(status.ready?'보상 받기':'목표 보기')+'</span></div>';}
}
function goals(tab='오늘의 목표'){
  refreshDay(state);openSheet('우리의 작은 약속','돌보고 · 꾸미고 · 함께 자라요');const content=$('#sheet-content');
  const info=levelInfo(state.progress.xp);content.innerHTML='<div class="quest-banner">'+iconHTML('flower')+'<div><b>우리 집 Lv. '+info.level+'</b><p>'+(info.max?'모든 레벨 해금 완료!':('다음 레벨까지 '+(info.next-state.progress.xp)+' XP'))+'</p></div><span>'+iconHTML('acorn')+' '+state.coins.toLocaleString('ko-KR')+'</span></div><div class="tabs quest-tabs"></div><div id="quest-list"></div>';
  for(const label of ['오늘의 목표','성장 목표','시간 해금','해금 도감']){const b=document.createElement('button');b.textContent=label;b.className=tab===label?'active':'';b.onclick=()=>goals(label);$('.quest-tabs').append(b);}
  if(tab==='시간 해금'){timeUnlockSheet();return;}
  if(tab==='해금 도감'){
    $('#quest-list').innerHTML='<p class="quest-note">레벨 또는 플레이 시간·시간대 조건을 채우면 열려요. 가구는 해금 후 도토리로 구입해요.</p><div class="unlock-grid"></div>';
    const items=[...CATALOG.filter(i=>FURNITURE_LEVELS[i.id]>1).map(i=>({id:i.id,kind:'furniture',title:i.name,required:FURNITURE_LEVELS[i.id],icon:'decorate'})),...SKINS.slice(1).map(i=>({id:i.id,kind:'skin',title:i.country+' · '+i.name,required:SKIN_LEVELS[i.id],icon:'skins'}))].sort((a,b)=>a.required-b.required);
    for(const item of items){const open=isUnlocked(state,item.kind,item.id),el=document.createElement('button');el.className='unlock-item'+(open?' unlocked':'');el.innerHTML=iconHTML(item.icon)+'<div><b>'+item.title+'</b><small>'+(open?'해금 완료 · 보러 가기':unlockCondition(state,item.kind,item.id))+'</small></div>'+iconHTML(open?'check':'lock');el.onclick=()=>open?(item.kind==='skin'?skins():shop()):toast(unlockCondition(state,item.kind,item.id));$('.unlock-grid').append(el);}return;
  }
  const daily=tab==='오늘의 목표';$('#quest-list').innerHTML='<p class="quest-note">'+(daily?'매일 한국 시간 자정에 새 약속이 도착해요.':'작은 첫 경험부터, 다정한 집사까지. 한 번씩 선물을 받아요.')+'</p><div class="quest-cards'+(daily?' daily-quests':'')+'"></div>';
  for(const goal of daily?DAILY_GOALS:GOALS){const status=goalStatus(state,goal,daily),card=document.createElement('article');card.className='quest-card'+(status.claimed?' claimed':status.ready?' ready':'');card.innerHTML='<div class="quest-art">'+iconHTML(goal.icon)+'</div><div class="quest-copy"><b>'+goal.title+'</b><p>'+goal.description+'</p><div class="quest-track"><i style="width:'+status.value/goal.target*100+'%"></i></div><small>'+status.value+' / '+goal.target+'</small></div><div class="quest-reward"><span>'+iconHTML('acorn')+' '+goal.coins+' <em>+'+goal.xp+' XP</em></span><button '+(!status.ready||status.claimed?'disabled':'')+'>'+iconHTML(status.claimed?'check':'gift')+(status.claimed?'받았어요':status.ready?'선물 받기':'진행 중')+'</button></div>';
    card.querySelector('button').onclick=()=>{const before=level(state),reward=claimGoal(state,goal.id,daily);if(!reward){updateUI();goals(tab);return;}log(goal.title+' 목표 완료! '+reward.coins+' 도토리와 '+reward.xp+' XP를 받았어요.');updateUI();tone();goals(tab);showReaction('gift');toast('선물 도착! +'+reward.coins+' 도토리 · +'+reward.xp+' XP');announceLevel(before);};$('.quest-cards').append(card);
  }
}

function timeUnlockSheet(){
  const period=timePeriod();$('#quest-list').innerHTML='<div class="time-summary"><div>'+iconHTML(period.icon)+'<b id="time-total">함께한 시간 '+formatPlayTime(state.progress.playSeconds)+'</b></div><small>한국 시간 · '+period.name+' '+period.hours+'<br>게임 화면을 보고 있는 시간만 누적돼요. 메뉴·꾸미기 시간도 포함해요.</small></div><div class="period-visits"></div><p class="quest-note">누적 시간 + 해당 시간대 방문 1분, 또는 레벨을 채우면 해금! 한번 열린 항목은 계속 사용할 수 있어요. 가구는 해금 후 도토리로 구입해요.</p><div class="time-unlock-list"></div>';
  for(const p of PERIODS){const chip=document.createElement('div');chip.className='period-visit'+(period.id===p.id?' current':'');chip.innerHTML=iconHTML(p.icon)+'<div><b>'+p.name+' <span>'+p.hours+'</span></b><small data-period="'+p.id+'"></small></div>';$('.period-visits').append(chip);}
  const entries=Object.entries(TIME_UNLOCKS).filter(([kind])=>kind!=='friend').flatMap(([kind,items])=>Object.entries(items).map(([id,rule])=>({kind,id,rule}))).sort((a,b)=>a.rule.minutes-b.rule.minutes);
  for(const {kind,id,rule} of entries){const open=isUnlocked(state,kind,id),title=kind==='friend'?SPECIES.find(s=>s[0]===id).slice(1).join(' '):kind==='skin'?findSkin(id).name:CATALOG.find(i=>i.id===id).name,art=kind==='furniture'?'<img class="time-item-art" src="assets/'+id+'.webp" alt="">':iconHTML(kind==='friend'?'friends':'skins');const el=document.createElement('article');el.className='time-unlock-card'+(open?' unlocked':'');el.dataset.kind=kind;el.dataset.id=id;el.innerHTML=art+'<div class="time-item-copy"><b>'+title+'</b><small>누적 '+rule.minutes+'분'+(rule.period?' · '+PERIODS.find(p=>p.id===rule.period).name+' 방문 1분':'')+'</small><div class="quest-track"><i></i></div><span class="time-condition"></span></div><button>'+iconHTML(open?'check':'lock')+(open?'보러 가기':'조건 보기')+'</button>';el.querySelector('button').onclick=()=>isUnlocked(state,kind,id)?(kind==='skin'?skins():shop()):toast(unlockCondition(state,kind,id));$('.time-unlock-list').append(el);}
  updateTimeSheet();
}
function updateTimeSheet(){
  if(!$('#time-total'))return;$('#time-total').textContent='함께한 시간 '+formatPlayTime(state.progress.playSeconds);
  for(const el of document.querySelectorAll('[data-period]')){const seconds=Math.min(60,Math.floor(state.progress.periodSeconds[el.dataset.period]||0));el.textContent=seconds>=60?'방문 완료':seconds+' / 60초';}
  for(const el of document.querySelectorAll('.time-unlock-card')){const rule=TIME_UNLOCKS[el.dataset.kind][el.dataset.id];el.querySelector('.quest-track i').style.width=Math.min(100,state.progress.playSeconds/(rule.minutes*60)*100)+'%';el.querySelector('.time-condition').textContent=isUnlocked(state,el.dataset.kind,el.dataset.id)?'해금 완료':unlockCondition(state,el.dataset.kind,el.dataset.id);}
}
function restaurant(tab='식당 메뉴',filter='전체'){
  openSheet('복실복실 식당','정성 가득한 요리를 우리 친구에게');
  $('#sheet-content').innerHTML='<div id="food-shop" data-tab="'+tab+'" data-filter="'+filter+'"><div class="food-banner">'+iconHTML('feed')+'<div><b>숲속 식당의 따뜻한 한 끼</b><small>식당 32종 · 텃밭 요리 8종 · 맛본 요리 '+state.food.eaten.filter(id=>id!=='carrot').length+' / 40</small></div><span>'+iconHTML('acorn')+' '+state.coins+'</span></div><div class="tabs food-tabs"></div><div class="food-filters"></div><p class="quest-note">'+(tab==='우리 냉장고'?'먹고 싶은 요리를 골라 주세요. 한 접시는 식사를 마쳤을 때 사용돼요.':'레벨 또는 플레이 시간·시간대 방문으로 요리가 열려요. 주문한 요리는 냉장고에 보관돼요.')+'</p><div class="food-grid"></div></div>';
  $('.food-tabs').replaceWith(gardenUI.navigation(tab));
  for(const name of ['전체','정식','간식','음료']){const b=document.createElement('button');b.textContent=name;b.className=filter===name?'active':'';b.onclick=()=>restaurant(tab,name);$('.food-filters').append(b);}
  const dishes=FOODS.filter(f=>(tab==='우리 냉장고'||!f.garden)&&(f.id==='carrot'||filter==='전체'||f.category===filter)&&(tab!=='우리 냉장고'||f.id==='carrot'||state.food.stock[f.id]>0));
  for(const f of dishes){const open=isFoodUnlocked(state,f.id),stock=state.food.stock[f.id]||0,favorite=favoriteKnown(state,f.id),card=document.createElement('article');card.className='food-card'+(open?'':' locked');card.innerHTML='<div class="food-art"><img src="'+f.icon+'" alt="'+f.name+'" loading="lazy">'+(favorite?'<span>좋아하는 맛</span>':'')+'</div><b>'+f.name+'</b><p>'+f.description+'</p><div class="food-effects" aria-label="포만감 '+f.hunger+', 행복 '+(f.happy+(favorite?5:0))+', 기운 '+f.energy+' 증가">'+iconHTML('feed')+' +'+f.hunger+' '+iconHTML('pet')+' +'+(f.happy+(favorite?5:0))+(f.energy?' '+iconHTML('sleep')+' +'+f.energy:'')+'</div><small class="food-condition">'+(open?(f.id==='carrot'?'무료 · 언제든 먹을 수 있어요':'냉장고 '+stock+'접시'):foodCondition(state,f))+'</small><div class="food-buttons"></div>';
    const buttons=card.querySelector('.food-buttons');if(tab==='식당 메뉴'&&f.price>0){const buy=document.createElement('button');buy.className='food-buy';buy.disabled=!open||state.coins<f.price;buy.innerHTML=iconHTML(open?'acorn':'lock')+' '+f.price+' 주문';buy.setAttribute('aria-label',f.name+' '+f.price+' 도토리로 주문');buy.onclick=()=>{const meal=buyFood(state,f.id);if(!meal){toast('해금 조건과 도토리를 확인해 주세요.');return;}recordEvent(state,'foodbuy');log(f.name+' 한 접시를 '+f.price+' 도토리로 주문했어요.');updateUI();tone();restaurant(tab,filter);toast(f.name+'가 냉장고에 도착했어요!');};buttons.append(buy);}
    if(f.id==='carrot'||stock>0){const feed=document.createElement('button');feed.className='food-serve';feed.textContent='먹이기'+(stock?' · '+stock+'접시':'');feed.setAttribute('aria-label',f.name+' 먹이기');feed.onclick=()=>{if(edit||pet.action){toast(edit?'꾸미기를 완료한 뒤 먹여 주세요.':'친구가 하던 일을 마칠 때까지 기다려 주세요.');return;}image(f.icon.replace('assets/',''));closeSheet();care('feed',f.id);};buttons.append(feed);}
    $('.food-grid').append(card);
  }
}
function unlockedName(entry){return entry.kind==='furniture'?CATALOG.find(i=>i.id===entry.id).name:entry.kind==='skin'?findSkin(entry.id).name:SPECIES.find(s=>s[0]===entry.id)[2];}
let playClock=performance.now(),timeSave=0,nativePaused=false;
setInterval(()=>{
  gardenUI.updateTimers();const now=performance.now(),seconds=(now-playClock)/1000;playClock=now;if(document.hidden||nativePaused)return;
  const opened=addPlayTime(state,seconds).filter(entry=>entry.kind!=='friend'),newFood=refreshFoodUnlocks(state);timeSave+=seconds>0&&seconds<=5?seconds:0;
  if(timeSave>=5||opened.length||newFood.length){updateUI();updateTimeSheet();}
  if(opened.length){log('함께한 시간으로 '+opened.map(unlockedName).join(', ')+' 해금!');toast('우리 집에 새 선물! '+opened.map(unlockedName).join(' · ')+' 해금');tone();if($('.time-unlock-list'))timeUnlockSheet();else if($('.unlock-grid'))goals('해금 도감');else if($('.skin-grid'))skins();else if($('#sheet-title').textContent==='집 꾸미기')shop($('.tabs button.active')?.textContent||'전체');}
  if(newFood.length){log('식당의 새 요리 '+newFood.map(f=>f.name).join(', ')+' 해금!');toast('식당 신메뉴! '+newFood.map(f=>f.name).join(' · '));if($('#food-shop'))restaurant($('#food-shop').dataset.tab,$('#food-shop').dataset.filter);}
  if(timeSave>=15){save();timeSave=0;}
},1000);
function resize(){const rect=room.getBoundingClientRect();width=rect.width;height=rect.height;dpr=Math.min(devicePixelRatio||1,2);room.width=Math.round(width*dpr);room.height=Math.round(height*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);}
new ResizeObserver(resize).observe(room);
const ACTION_ART={feed:'eat',pet:'pet',play:'toy',clean:'groom',sleep:'sleep',carry:'carry',look:'look',drink:'drink',rest:'rest',sniff:'sniff',stretch:'stretch',jump:'jump',rub:'rub',habit:'habit'};
function drawPet(c,x,y,size,species,time=0,walking=false,dir=1,action=null,previewLook=null,motionPose=null){
 const growth=growthInfo(state,species),savedLook=previewLook||state.desktop.outfits[species]||{style:'none',color:0},age=savedLook.adultPreview?'adult':growth.stage==='baby'?'baby':'adult';
 const look=age==='baby'?{style:'none'}:savedLook,bank=action?ACTION_ART[action]||'idle':walking?'walk':'idle';
 const current=animationCatalog.base[species][age];
 const pose=motionPose||{bank,elapsed:time,duration:current[bank]?.duration||4.8};
 const resolved=resolveAnimation(animationCatalog,species,age,look,pose);if(!resolved)return;
 let spec=resolved.spec,sheet=atlas(spec.file),sampling={...pose,bank:resolved.bank};
 if(!resolved.supported){sampling.elapsed=time;sampling.duration=spec.duration||4.8;delete sampling.progress;}
 const hop=current.walk.hop;if(pose.bank==='walk'&&resolved.bank==='walk'&&hop)sampling.progress=hopPhase(pose.elapsed||0,hop);
 if(!sheet){const idle=resolveAnimation(animationCatalog,species,age,look,{bank:'idle'});spec=idle.spec;sheet=atlas(spec.file);sampling={bank:'idle',elapsed:time,duration:spec.duration||4.8};}
 if(!sheet)return;
 const frame=animationFrame(spec,sampling),side=spec.cell_size,anchor=spec.anchor||[128,232],unit=size/256*(look.adultPreview?1:growth.scale);
 c.save();c.translate(x,y);c.scale(dir,1);
 if(pose.bank==='walk'&&resolved.bank==='walk'&&hop)c.translate(0,-hopLift(pose.elapsed||0,hop)*unit);
 if(pose.bank==='emotions'){const motion=expressionPose(SPECIES.findIndex(i=>i[0]===species),pose.emotion,pose.event,pose.progress??((pose.elapsed%(pose.duration||2.8))/(pose.duration||2.8)),pose.strength);c.translate(motion.x*unit,motion.y*unit);c.rotate(motion.angle);}
 // Restore the cropped source coordinates inside one clipped cel, without
 // duplicating a 60-frame bank in another large canvas allocation.
 c.translate(-anchor[0]*unit,-anchor[1]*unit);c.scale(unit,unit);c.beginPath();c.rect(0,0,side,side);c.clip();
 c.drawImage(sheet,spec.offset[0]-(frame%spec.columns)*side,spec.offset[1]-Math.floor(frame/spec.columns)*side);c.restore();
}
function furnitureFile(item,f){return furnitureAsset(item,f);}
function roomFurniture(){return state.furniture.filter(f=>visibleFurniture(CATALOG.find(i=>i.id===f.id),state.species));}
function furnitureRect(f){const item=CATALOG.find(i=>i.id===f.id),img=image(furnitureFile(item,f));const ratio=img.naturalHeight/(img.naturalWidth||1);const w=Math.min(width*item.w*clamp(Number(f.scale)||1,.6,1.6),height*(item.wall?.27:.53)*clamp(Number(f.scale)||1,.6,1.6)/(ratio||1));const h=w*(ratio||.75);return {x:f.x*width-w/2,y:f.y*height-h,w,h};}
function drawFurniture(f){const item=CATALOG.find(i=>i.id===f.id),img=image(furnitureFile(item,f)),r=furnitureRect(f);if(img.complete&&img.naturalWidth){ctx.save();ctx.translate(r.x+r.w/2,r.y+r.h/2);if(f.id==='toy_ball')ctx.rotate(f.roll||0);if(f.id==='acorn'&&toySession?.id==='acorn')ctx.rotate(Math.sin(animTime*12)*.16);if(f.flip)ctx.scale(-1,1);ctx.drawImage(furnitureImage(img,f.id,f.style),-r.w/2,-r.h/2,r.w,r.h);ctx.restore();}if(edit){ctx.save();ctx.strokeStyle=selected===f.id?'#526e55':'#fdf9ebbb';ctx.lineWidth=selected===f.id?2:1;ctx.setLineDash([5,4]);ctx.strokeRect(r.x-3,r.y-3,r.w+6,r.h+6);if(selected===f.id){ctx.fillStyle='#526e55';ctx.fillRect(r.x+r.w/2-4,r.y+r.h-4,8,8);}ctx.restore();}}
function floorTarget(x,y){return{x:clamp(x,.09,.91),y:clamp(y,state.desktop.settings.activitySpace==='room'?.50:.72,.94)};}
function clearFloorPoint(){for(let n=0;n<15;n++){const q=floorTarget(.12+Math.random()*.76,.59+Math.random()*.32);if(!roomFurniture().some(f=>!CATALOG.find(i=>i.id===f.id).wall&&f.id!=='rug'&&Math.abs(q.x-f.x)<.10&&Math.abs(q.y-f.y)<.08))return q;}return{x:.5,y:.88};}
function reward(key,amount){const day=dayKey(),tag=day+':'+key;const count=state.daily[tag]||0;state.daily[tag]=count+1;const earned=count<5?amount:0;state.coins+=earned;state.bond+=count<5?3:1;return earned;}
function drawIcon(c,name,x,y,size){const art=image('ui-icons/'+name+'.png');if(art.complete&&art.naturalWidth)c.drawImage(art,x-size/2,y-size/2,size,size);}
function burst(icon){for(let i=0;i<5;i++)particles.push({x:pet.x*width+(Math.random()-.5)*25,y:pet.y*height-height*.13,age:0,icon:i===0?icon:'pet',vx:(Math.random()-.5)*25});}
function finishCare(action){const data={feed:['hunger',25,'feed',12,'맛있는 당근을 먹었어요.'],pet:['happy',15,'pet',8,'따뜻하게 쓰다듬어 주었어요.'],play:['happy',22,'play',15,'실뭉치와 신나게 놀았어요.'],clean:['clean',30,'clean',10,'뽀송뽀송 목욕을 했어요.'],sleep:['energy',35,'sleep',8,'포근하게 쉬었어요.']}[action];let meal=null,newTaste=false;if(action==='feed'){newTaste=!state.food.eaten.includes(pet.action.foodId)&&pet.action.foodId!=='carrot';meal=eatFood(state,pet.action.foodId);if(!meal){pet.action=null;toast('요리를 찾을 수 없어요. 냉장고를 확인해 주세요.');return;}}else state.stats[data[0]]=clamp(state.stats[data[0]]+data[1],0,100);if(action==='play')state.stats.energy=clamp(state.stats.energy-8,0,100);const before=level(state);recordEvent(state,action);completeDesktopActivity(state,action);if(newTaste)recordEvent(state,'taste');const earned=reward(action,data[3]);burst(data[2]);tone();const completedToy=pet.action?.toy;const message=meal?meal.name+' 냠냠!'+(meal.favorite?' 좋아하는 요리예요.':''):(completedToy?TOYS.find(t=>t.id===completedToy).name+'와 즐겁게 놀았어요.':data[4]);toast(name()+' '+message+(earned?' +'+earned+' 도토리':''));log(name()+'와 '+message);pet.action=null;pet.until=animTime+3;updateUI();announceLevel(before);showReaction(action==='feed'?(meal?.favorite?'favorite_meal':'meal'):({pet:'pet',play:'toy',clean:'groom',sleep:'wake'})[action]);}
function care(action,foodId=null){if(gardenSpace.active)gardenSpace.home();interruptAutonomy();followMode=false;if(edit){toast('꾸미기를 완료한 뒤 친구와 놀아주세요.');return;}if(pet.action){toast('친구가 하던 일을 마칠 때까지 기다려 주세요.');return;}if(action==='feed'&&!foodId){restaurant();return;}if(action==='feed'&&(!FOODS.some(f=>f.id===foodId)||(foodId!=='carrot'&&!(state.food.stock[foodId]>0)))){toast('냉장고에 요리가 없어요. 식당에서 먼저 주문해 주세요.');return;}const targetId={feed:'table',sleep:'sofa',play:'rug'}[action];const target=roomFurniture().find(f=>f.id===targetId)||roomFurniture().find(f=>CATALOG.find(i=>i.id===f.id).kind===({feed:'table',sleep:'sofa'}[action]));const duration={feed:4.8,pet:2.4,play:6.4,clean:6.8,sleep:10.8}[action];pet.action={type:action,foodId,elapsed:0,duration,remaining:null};pet.target=target?floorTarget(target.x,target.y+.05):null;if(!pet.target)pet.action.remaining=duration;toast({feed:'식탁으로 총총, 요리를 먹으러 가요.',pet:'따뜻한 손길을 기다리고 있어요.',play:'실뭉치와 놀아볼까요?',clean:'보송보송 씻는 시간!',sleep:'잠깐, 포근하게 쉬어요.'}[action]);}
function roomPose(){
 if(heldPet)return holdPose(Math.max(0,animTime-heldPet.at),heldPet.moved);
 if(pet.target)return {bank:'walk',elapsed:pet.walkElapsed||0,duration:animationCatalog.base[state.species][growthInfo(state).stage==='baby'?'baby':'adult'].walk.duration||2.2};
 const a=pet.action;if(!a)return {bank:'idle',elapsed:animTime,duration:4.8};
 const elapsed=a.elapsed||0,progress=clamp(elapsed/(a.duration||2.4),0,1);
 if(a.type==='expression')return {bank:'emotions',emotion:a.emotion,event:a.event,strength:a.strength,elapsed,progress,duration:a.duration};
 if(a.type==='motion')return {bank:a.bank,elapsed,progress,duration:a.duration};
 if(a.type==='transition'){if(a.long&&elapsed>.28)return {bank:'hold-recover',elapsed,progress:(elapsed-.28)/.36};return {bank:a.bank,elapsed,progress:a.reverse?1-elapsed/.28:elapsed/.28};}
 if(a.type==='habit')return {bank:ACTION_ART[a.pose]||a.pose,elapsed,duration:HABITS[state.species].seconds};
 if(a.type==='life')return {bank:a.activity==='drink'?'drink':'home-'+a.kind,elapsed,progress,duration:a.duration};
 if(a.type==='sleep')return {bank:'home-nap',elapsed,progress,duration:a.duration};
 if(a.type==='clean')return {bank:'home-groom',elapsed,progress,duration:a.duration};
 if(a.type==='play'&&!a.toy)return {bank:'home-play',elapsed,progress,duration:a.duration};
 if(a.type==='pet')return {bank:'emotions',emotion:'happy',elapsed};
 return {bank:ACTION_ART[a.type]||'idle',elapsed,progress:a.toy?undefined:progress,duration:a.duration};
}
let nextStumble=30,nextSneeze=45,nextDeliveryTime=3,idleElapsed=0;
function startSilly(bank,resume=null){const age=growthInfo(state).stage==='baby'?'baby':'adult',resolved=resolveAnimation(animationCatalog,state.species,age,state.desktop.outfits[state.species],{bank});if(!resolved?.supported)return false;pet.target=null;pet.action={type:'motion',bank,automatic:!resume||Boolean(resume.automatic),resume,elapsed:0,duration:bank==='stumble'?4.8:2.4,remaining:bank==='stumble'?4.8:2.4};if(bank==='stumble')nextStumble=animTime+60+Math.random()*30;else nextSneeze=animTime+45;return true;}
function advanceDelivery(){if(animTime<nextDeliveryTime||pet.action||pet.target||heldPet||edit||followMode||state.stats.hunger<48||state.stats.hydration<45||state.stats.energy<35)return;const id=nextDelivery(state,CATALOG,furnitureOpen);if(!id)return;state.desktop.autoDelivered.push(id);state.desktop.arrivalSeen.push(id);state.owned.push(id);if(!state.furniture.some(f=>f.id===id))state.furniture.push({id,x:clamp(pet.x+.17,.16,.84),y:.85});nextDeliveryTime=animTime+2.5;burst('gift');save();updateUI();toast((CATALOG.find(i=>i.id===id)?.name||id)+' 선물이 도착했어요!');tone();}
function frame(ms){const dt=Math.min(.05,(ms-last)/1000||0);last=ms;
  const busy=Boolean($('#overlay').hidden===false);
  if(!busy&&!nativePaused&&!document.hidden)animTime+=dt;
  if(gardenSpace.active){gardenSpace.draw(animTime);const c=$('#portrait').getContext('2d');c.clearRect(0,0,160,160);drawPet(c,80,143,154,state.species,animTime,false,1);requestAnimationFrame(frame);return;}
  if(!edit&&!busy&&!nativePaused&&!document.hidden){idleElapsed=!pet.action&&!pet.target&&!heldPet?idleElapsed+dt:0;advanceDelivery();if(!pet.action&&!pet.target&&!heldPet&&!followMode&&animTime>=nextSneeze&&idleElapsed>3&&state.stats.hunger>=30&&state.stats.hydration>=30&&state.stats.energy>=30)startSilly('sneeze');}
  if(!edit&&!busy&&!nativePaused&&!document.hidden){if(pet.action&&!pet.target)pet.action.elapsed=(pet.action.elapsed||0)+dt;advanceToy(dt);if(pet.target){const dx=(pet.target.x-pet.x)*width,dy=(pet.target.y-pet.y)*height,dist=Math.hypot(dx,dy),hop=animationCatalog.base[state.species][growthInfo(state).stage==='baby'?'baby':'adult'].walk.hop,speed=Math.max(18,height*.13)*(hop?hopTravelRate(pet.walkElapsed||0,dt,hop):1);pet.walkElapsed=(pet.walkElapsed||0)+dt;if(dist<speed*dt+1){pet.x=pet.target.x;pet.y=pet.target.y;pet.target=null;pet.until=animTime+2+Math.random()*3;if(pet.action)pet.action.remaining=pet.action.toy?null:pet.action.duration||2.4;if(!toySession&&!followMode&&!heldPet&&animTime>=nextStumble&&pet.walkElapsed>=.35&&state.stats.hunger>=30&&state.stats.hydration>=30&&state.stats.energy>=30)startSilly('stumble',pet.action?{...pet.action}:null);}else{pet.dir=dx<0?-1:1;pet.x+=dx/dist*speed*dt/width;pet.y+=dy/dist*speed*dt/height;}}
    else if(pet.action?.remaining!=null){pet.action.remaining-=dt;if(pet.action.remaining<=0){if(pet.action.type==='life')finishLife();else if(pet.action.type==='habit')finishHabit();else if(['expression','transition','motion'].includes(pet.action.type)){const event=pet.action.after,resume=pet.action.resume;pet.action=resume||null;pet.words=null;pet.until=animTime+5;if(event==='dizzy')pet.action={type:'motion',bank:'dizzy',automatic:true,elapsed:0,duration:2.4,remaining:2.4,after:'set_down'};else if(event)showReaction(event);}else finishCare(pet.action.type);}}
    else if(animTime>pet.until&&!heldPet&&!followMode){const usable=roomFurniture().filter(f=>LIFE[activityFor(f.id)]&&!CATALOG.find(i=>i.id===f.id).wall);if(usable.length&&Math.random()<.35)beginLife(usable[Math.floor(Math.random()*usable.length)].id,true);else if(Math.random()<.25)beginHabit(true);else pet.target=clearFloorPoint();}
  }
  ctx.clearRect(0,0,width,height);
  if(background.complete&&background.naturalWidth)ctx.drawImage(background,0,0,width,height);else{ctx.fillStyle='#f0e6cc';ctx.fillRect(0,0,width,height*.45);ctx.fillStyle='#dbc39d';ctx.fillRect(0,height*.45,width,height*.55);ctx.strokeStyle='#c4aa84';for(let y=height*.5;y<height;y+=height*.09){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(width,y);ctx.stroke();}}
  for(const f of roomFurniture()){const r=furnitureRect(f),margin=r.w/width/2+.01;f.x=clamp(f.x,margin,1-margin);}
  if(!pet.target)pet.walkElapsed=0;
  const layers=roomFurniture().map(f=>({order:f.stackOrder||0,y:furnitureDepth(f),draw:()=>drawFurniture(f)}));
  const size=Math.min(width*.16,height*.37),px=pet.x*width,py=pet.y*height;
  layers.push({order:Infinity,y:heldPet?2:pet.y,draw:()=>{ctx.fillStyle='#756c4830';ctx.beginPath();ctx.ellipse(px,py,size*.23,size*.06,0,0,Math.PI*2);ctx.fill();drawPet(ctx,px,py,size,state.species,animTime,Boolean(pet.target),pet.dir,null,null,roomPose());if(pet.action&&!pet.target&&!['habit','expression','transition','motion'].includes(pet.action.type)){const iconSize=Math.max(22,size*.28),iconY=py-size*.83+Math.sin(animTime*3)*3;const meal=pet.action.type==='feed'&&FOODS.find(f=>f.id===pet.action.foodId);if(meal){const art=image(meal.icon.replace('assets/',''));if(art.complete&&art.naturalWidth)ctx.drawImage(art,px-iconSize/2,iconY-iconSize/2,iconSize,iconSize);}else drawIcon(ctx,pet.action.type==='life'?LIFE[pet.action.activity].icon:pet.action.type,px,iconY,iconSize);}}});
  layers.sort((a,b)=>a.order-b.order||a.y-b.y).forEach(l=>l.draw());
  if(pet.words&&pet.action?.type==='expression'){ctx.save();ctx.font='bold 10px sans-serif';const bubbleWidth=ctx.measureText(pet.words).width+18,bx=clamp(px-bubbleWidth/2,8,width-bubbleWidth-8),by=Math.max(55,py-size-15);ctx.fillStyle='#fffbf0f0';ctx.beginPath();ctx.roundRect(bx,by,bubbleWidth,24,9);ctx.fill();ctx.fillStyle='#6e765b';ctx.fillText(pet.words,bx+9,by+16);ctx.restore();}
  if(pet.action?.type==='play'&&!pet.action.toy&&!pet.target)drawIcon(ctx,'play',px+Math.sin(animTime*4)*size*.5,py,Math.max(24,size*.29));
  particles=particles.filter(p=>p.age<1.8);for(const p of particles){p.age+=dt;p.y-=30*dt;p.x+=p.vx*dt;ctx.save();ctx.globalAlpha=1-p.age/1.8;drawIcon(ctx,p.icon,p.x,p.y,24);ctx.restore();}
  const portrait=$('#portrait'),pc=portrait.getContext('2d');pc.clearRect(0,0,160,160);drawPet(pc,80,143,154,state.species,animTime,false,1);
  requestAnimationFrame(frame);
}
function point(e){const r=room.getBoundingClientRect();return{x:(e.clientX-r.left)/r.width,y:(e.clientY-r.top)/r.height};}
function hitFurniture(p){return [...roomFurniture()].sort((a,b)=>(b.stackOrder||0)-(a.stackOrder||0)||furnitureDepth(b)-furnitureDepth(a)).find(f=>{const r=furnitureRect(f);return p.x*width>=r.x&&p.x*width<=r.x+r.w&&p.y*height>=r.y&&p.y*height<=r.y+r.h;});}
room.addEventListener('pointerdown',e=>{
 const p=point(e),hit=hitFurniture(p);room.setPointerCapture(e.pointerId);
 if(edit){if(hit){selected=hit.id;drag={item:hit,originalX:hit.x,originalY:hit.y,dx:p.x-hit.x,dy:p.y-hit.y};}else selected=null;return;}
 if(followMode&&!pet.action){followStart=p;pet.target=floorTarget(p.x,p.y);return;}
 interruptAutonomy();if(pet.action)return;
 const size=Math.min(width*.16,height*.37);
 if(Math.abs(p.x-pet.x)*width<size*.45&&p.y*height>pet.y*height-size*.85&&p.y*height<pet.y*height+size*.1){heldPet={start:p,original:{x:pet.x,y:pet.y},moved:false,at:animTime};pet.target=null;return;}
 if(hit&&['toy_ball','toy_mouse','acorn'].includes(hit.id)){toyDrag={item:hit,start:p,dx:p.x-hit.x,direction:1,moved:false};return;}
 if(hit&&LIFE[activityFor(hit.id)]){beginLife(hit.id);return;}
 if(hit?.id==='rug'){care('play');return;}
 if(p.y>.5){pet.target=floorTarget(p.x,p.y);$('#room-tip').textContent='총총, 그쪽으로 갈게요!';setTimeout(()=>$('#room-tip').textContent='친구나 가구를 톡 눌러 함께해요',2500);}
});
room.addEventListener('pointermove',e=>{
 const p=point(e);
 if(drag){const f=drag.item,r=furnitureRect(f),margin=r.w/width/2+.01;f.x=clamp(p.x-drag.dx,margin,1-margin);f.y=clamp(p.y-drag.dy,CATALOG.find(i=>i.id===f.id).wall?.20:.55,CATALOG.find(i=>i.id===f.id).wall?.45:.97);return;}
 if(heldPet){if(Math.hypot(p.x-heldPet.start.x,p.y-heldPet.start.y)>.035)heldPet.moved=true;if(heldPet.moved){pet.x=clamp(heldPet.original.x+p.x-heldPet.start.x,.12,.88);pet.y=clamp(heldPet.original.y+p.y-heldPet.start.y,.25,.94);}return;}
 if(toyDrag){const f=toyDrag.item,previous=f.x;f.x=clamp(p.x-toyDrag.dx,.15,.85);if(Math.abs(f.x-previous)>.001)toyDrag.direction=Math.sign(f.x-previous);if(f.id==='toy_ball')f.roll=(f.roll||0)+(f.x-previous)*width/Math.max(10,width*.035);toyDrag.moved ||= Math.abs(p.x-toyDrag.start.x)>.01;return;}
 if(followMode&&followStart){followMoved+=Math.hypot(p.x-followStart.x,p.y-followStart.y);followStart=p;pet.target=floorTarget(p.x,p.y);}
});
function endDrag(e){
 if(drag){arrangementChanged ||= Math.hypot(drag.item.x-drag.originalX,drag.item.y-drag.originalY)>.003;drag=null;save();}
 if(heldPet){const held=heldPet,seconds=animTime-held.at;heldPet=null;if(!held.moved&&seconds<.35&&e.type!=='pointercancel'){care('pet');}else{const dropHeight=Math.max(0,.58-pet.y),floor=floorTarget(pet.x,pet.y);pet.x=floor.x;pet.y=floor.y;const long=seconds>=2.2,quarter=Math.floor(Math.max(0,seconds-2.48)/.4)%4;pet.action={type:'transition',bank:long?'hold-release'+quarter:'hold-pickup',reverse:!long,long,elapsed:0,duration:long?.64:.28,remaining:long?.64:.28,after:dropHeight>.12?'dizzy':long?'held_long':'set_down'};pet.until=animTime+2;toast('사뿐, 친구를 내려놓았어요.');}}
 if(toyDrag){const t=toyDrag;toyDrag=null;save();if(e.type!=='pointercancel')startToy(t.item.id,t.direction);}
 if(followMode&&followStart){const walked=followMoved>=.25&&e.type!=='pointercancel';followMode=false;followStart=null;if(walked){pet.action={type:'play',remaining:2.4};toast('함께 산책하고 기분이 좋아졌어요.');}else toast('놀이 메뉴에서 산책을 다시 시작할 수 있어요.');followMoved=0;}
}
room.addEventListener('pointerup',endDrag);room.addEventListener('pointercancel',endDrag);
function roomCaption(){const skin=findSkin(state.skin);$('#room-caption').textContent=edit?'가구를 손가락으로 끌어 옮겨요':skin.country==='기본'?skin.name:skin.country+' · '+skin.name;$('#room-skins').title='현재 집: '+skin.name;}
function cancelInteraction(){if(heldPet){const p=floorTarget(pet.x,pet.y);pet.x=p.x;pet.y=p.y;}heldPet=null;toyDrag=null;toySession=null;followMode=false;followStart=null;followMoved=0;}
function setEdit(on){if(on)cancelInteraction();edit=on;$('#edit-label').hidden=!on;$('#room-tip').hidden=on;roomCaption();if(on){arrangementChanged=false;pet.target=null;pet.action=null;}else{selected=null;save();}}
$('#edit-style').onclick=()=>{const f=state.furniture.find(i=>i.id===selected);if(!f)return toast('먼저 꾸밀 가구를 눌러 주세요.');desktopUI.furnitureStyle(f);};
$('#edit-flip').onclick=()=>{const f=state.furniture.find(i=>i.id===selected);if(!f)return toast('먼저 바꿀 가구를 눌러 주세요.');f.flip=!f.flip;arrangementChanged=true;save();};
$('#edit-done').onclick=()=>{if(arrangementChanged)recordEvent(state,'arrange');setEdit(false);updateUI();log('우리 집 가구를 새롭게 배치했어요.');toast('나만의 포근한 집이 완성됐어요.');};
let sheetOpener=null;
function openSheet(title,kicker){$('#sheet-content').className='';skinRequest++;sheetOpener=document.activeElement;$('#sheet-title').textContent=title;$('#sheet-kicker').textContent=kicker;$('#overlay').hidden=false;$('#close-sheet').focus();}
function closeSheet(){skinRequest++;$('#overlay').hidden=true;$('#sheet-content').replaceChildren();sheetOpener?.focus();}
$('#close-sheet').onclick=closeSheet;$('#overlay').onclick=e=>{if(e.target===$('#overlay'))closeSheet();};
document.addEventListener('keydown',e=>{if(e.key==='Escape'){closeSheet();if(edit)setEdit(false);}if(e.key==='Tab'&&!$('#overlay').hidden){const controls=[...$('#overlay').querySelectorAll('button:not(:disabled),[tabindex="0"]')];const first=controls[0],last=controls.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}});
function shop(filter='기본·공유 가구'){if(gardenSpace.active)gardenSpace.home();openSheet('집 꾸미기','작은 취향이 모여, 포근한 우리 집');const content=$('#sheet-content');content.innerHTML=`<div class="shop-toolbar"><p>작은 가구 하나가, 우리 집을 더 포근하게.</p><button class="pill" id="arrange">가구 위치 옮기기 ${iconHTML('move')}</button></div><div class="tabs"></div><div class="cards"></div>`;$('#arrange').onclick=()=>{closeSheet();setEdit(true);};for(const cat of ['기본·공유 가구','고유 가구','집 스킨','전체','가구','소품','벽 장식','놀이감','친구 소품']){const b=document.createElement('button');b.textContent=cat;b.className=cat===filter?'active':'';b.onclick=()=>cat==='집 스킨'?skins():shop(cat);$('.tabs').append(b);}for(const item of CATALOG.filter(i=>visibleFurniture(i,state.species)&&(filter==='전체'||filter==='기본·공유 가구'&&!i.species||filter==='고유 가구'&&i.signature||i.cat===filter))){const unlocked=furnitureOpen(item),owned=state.owned.includes(item.id),placed=state.furniture.some(f=>f.id===item.id);const card=document.createElement('div');card.className='card'+(unlocked?'':' locked');card.innerHTML=`<img src="assets/${item.file||item.id+'.webp'}" alt="${item.name}" loading="lazy"><b>${item.name}</b><small class="price">${owned?'내 가구':item.signature?item.mbti+' · 친구의 고유 가구':iconHTML('acorn')+' '+item.price+' 도토리'}</small><button ${unlocked?'':'disabled'}>${!unlocked?iconHTML('lock')+' '+furnitureCondition(item):placed?'방에서 치우기':owned||item.signature?'방에 놓기':'구입하고 놓기'}</button>`;card.querySelector('button').onclick=()=>{if(!furnitureOpen(item))return;if(placed){state.furniture=state.furniture.filter(f=>f.id!==item.id);}else{if(!state.desktop.manualTools.includes(item.id))state.desktop.manualTools.push(item.id);if(!owned){if(state.coins<item.price){toast('도토리가 부족해요. 친구를 돌보며 모아보세요.');return;}state.coins-=item.price;state.owned.push(item.id);recordEvent(state,'buy');log(item.name+' 가구를 새로 구입했어요.');}state.furniture.push({id:item.id,x:.5+(Math.random()-.5)*.25,y:item.wall?.35:.75});}save();updateUI();shop(filter);};$('.cards').append(card);}}
let skinRequest=0;
function skins(){
  if(gardenSpace.active)gardenSpace.home();
  openSheet('작은 집, 세계 여행','친구와 떠나는 작은 세계 여행');
  const content=$('#sheet-content');
  content.innerHTML='<div class="skin-intro"><p>친구와 함께, 오늘은 다른 나라의 집으로.</p><small>레벨 또는 누적 플레이·시간대 방문으로 새 집이 열려요. 해금된 스킨은 무료예요.</small></div><div class="skin-grid"></div>';
  for(const skin of SKINS){
    const unlocked=isUnlocked(state,'skin',skin.id);const card=document.createElement('article');card.className='skin-card'+(unlocked?'':' locked')+(skin.id===state.skin?' selected':'');
    card.style.setProperty('--skin-color',skin.color);
    card.innerHTML=`<div class="skin-preview"><img src="assets/${skin.file}" alt="${skin.country} ${skin.name} 방 미리보기" loading="lazy"><span class="country-tag">${skin.country}</span></div><div class="skin-info"><h3>${skin.name}</h3><p>${skin.description}</p><button ${skin.id===state.skin||!unlocked?'disabled':''} aria-label="${skin.country} ${skin.name} 스킨 선택">${!unlocked?iconHTML('lock')+' '+unlockCondition(state,'skin',skin.id):skin.id===state.skin?iconHTML('check')+' 사용 중':'이 집으로 꾸미기'}</button></div>`;
    card.querySelector('button').onclick=async()=>{
      if(!isUnlocked(state,'skin',skin.id))return;const request=++skinRequest,button=card.querySelector('button');
      document.querySelectorAll('.skin-card button').forEach(b=>b.disabled=true);button.textContent='집을 준비하고 있어요…';
      try{
        const next=image(skin.file);await next.decode();if(request!==skinRequest)return;
        background=next;state.skin=skin.id;if(!state.progress.skins.includes(skin.id))state.progress.skins.push(skin.id);recordEvent(state,'skin');updateUI();roomCaption();log(skin.country+' · '+skin.name+' 스킨으로 집을 꾸몄어요.');closeSheet();tone();toast(skin.name+'에 오신 것을 환영해요!');
      }catch{
        imageCache.delete(skin.file);if(request===skinRequest){skins();$('.skin-intro small').textContent='방 그림을 불러오지 못했어요. 연결을 확인하고 다시 선택해 주세요.';}
      }
    };
    $('.skin-grid').append(card);
  }
}
$('#decorate').onclick=()=>shop();$('#food-menu').onclick=()=>restaurant();
$('#room-skins').onclick=skins;$('#wardrobe').onclick=()=>desktopUI.wardrobe();
$('#goals').onclick=()=>goals();$('#goal-peek').onclick=()=>goals();
$('.growth').onclick=()=>goals('해금 도감');
document.querySelectorAll('[data-care]').forEach(b=>b.onclick=()=>b.dataset.care==='play'?desktopUI.playroom():care(b.dataset.care));
function toggleSound(){sound=!sound;state.desktop.settings.sound=sound;save();$('#sound img').src='assets/ui-icons/'+(sound?'sound-on':'sound-off')+'.png';$('#sound').ariaLabel=sound?'소리 끄기':'소리 켜기';$('#sound').title=$('#sound').ariaLabel;$('#sound').setAttribute('aria-pressed',String(sound));tone();toast(sound?'효과음을 켰어요.':'효과음을 껐어요.');}$('#sound').onclick=toggleSound;
$('#fullscreen').onclick=async()=>{const ios=/iPhone|iPad|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);if(ios){if(navigator.standalone||matchMedia('(display-mode: standalone)').matches){toast('홈 화면 앱으로 열었어요. 휴대폰을 가로로 돌려주세요.');return;}openSheet('iPhone 홈 화면에 작은 집 담기','Safari에서 앱처럼 열 수 있어요');$('#sheet-content').innerHTML='<div class="empty-note"><p>Safari의 공유 버튼을 누르고 <strong>홈 화면에 추가</strong>를 선택해 주세요.</p><p>‘웹 앱으로 열기’ 옵션이 있으면 켜고 추가해 주세요. 홈 화면의 복슬복슬펫 아이콘으로 다시 열어 휴대폰을 가로로 돌리면 됩니다.</p><p>새 동물·옷·방 그림은 처음 열 때 인터넷이 필요해요. 불러온 그림은 기기에 보관되며 브라우저 저장 정리 시 다시 내려받아야 할 수 있어요. Android와 iPhone 사이의 진행 상황 동기화는 아직 제공하지 않습니다.</p></div>';return;}if(window.BoksilAndroid){toast('이미 가로 전체 화면으로 플레이 중이에요.');return;}try{if(document.fullscreenElement)await document.exitFullscreen();else await document.documentElement.requestFullscreen();try{await screen.orientation.lock('landscape');}catch{}}catch{toast('브라우저 메뉴에서 전체 화면으로 열어주세요.');}};
$('#snapshot').onclick=()=>{const photo=room.toDataURL('image/png');if(window.BoksilAndroid){window.BoksilAndroid.savePhoto(photo);return;}const a=document.createElement('a');a.download='복슬복슬펫-우리집.png';a.href=photo;a.click();toast('우리 집 사진을 저장했어요.');};
$('.portrait-hint button').onclick=()=>$('.portrait-hint').style.display='none';
setInterval(()=>{if(document.hidden||nativePaused||!$('#overlay').hidden||edit)return;for(const [key,rate]of Object.entries({hunger:.14,happy:.07,clean:.09,energy:.06,hydration:.18}))state.stats[key]=clamp(state.stats[key]-rate,0,100);updateUI();save();},15000);
window.addEventListener('boksil-app-pause',()=>{nativePaused=true;playClock=performance.now();cancelInteraction();if(pet.action?.toy)pet.action=null;save();});
window.addEventListener('boksil-app-resume',()=>{nativePaused=false;playClock=performance.now();last=performance.now();updateUI();updateTimeSheet();});
document.addEventListener('visibilitychange',()=>{playClock=performance.now();if(document.hidden){cancelInteraction();if(pet.action?.toy)pet.action=null;save();}else{last=performance.now();updateUI();updateTimeSheet();}});window.addEventListener('pagehide',save);
$('#sound img').src='assets/ui-icons/'+(sound?'sound-on':'sound-off')+'.png';$('#sound').setAttribute('aria-pressed',String(sound));$('#sound').ariaLabel=sound?'소리 끄기':'소리 켜기';$('#sound').title=$('#sound').ariaLabel;
const settingsUI=createSettingsUI({state,openSheet,closeSheet,save,toast,iconHTML,species:SPECIES,toggleSound,onSpace:()=>{cancelInteraction();pet.action=null;pet.target=null;pet.y=floorTarget(pet.x,pet.y).y;},placeWater:()=>{if(!state.owned.includes('water'))state.owned.push('water');if(!state.furniture.some(f=>f.id==='water'))state.furniture.push({id:'water',x:.63,y:.83});save();updateUI();toast('물컵을 꺼냈어요. 톡 눌러 물을 마셔요.');}});$('#settings').onclick=settingsUI;
updateUI();roomCaption();resize();save();requestAnimationFrame(frame);
if('serviceWorker'in navigator&&location.protocol!=='file:'&&location.hostname!=='appassets.androidplatform.net')navigator.serviceWorker.register('sw.js').catch(()=>{});
